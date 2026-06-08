//
//  AuthService.swift
//  Cardly
//
//  Firebase Email/Password auth. Holds the current user as observable state so
//  ContentView can gate Login vs. MainTabView purely by `currentUser == nil`.
//  On sign-up it also writes the users/{uid} profile document.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Lightweight current-user value the UI reads. Built from the Firebase user,
/// not decoded from Firestore — so it needs no @DocumentID.
struct AppUser: Identifiable, Equatable {
    let id: String          // Firebase uid
    let email: String
    var displayName: String
}

@MainActor
@Observable
final class AuthService {
    private(set) var currentUser: AppUser?
    var isWorking = false
    var errorMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?
    private let live: Bool

    /// Live init wires the Firebase auth-state listener. `live: false` is for
    /// SwiftUI previews (no Firebase calls). Use `AuthService.preview` there.
    init(live: Bool = true, previewUser: AppUser? = nil) {
        self.live = live
        guard live else { currentUser = previewUser; return }

        // Fires immediately with the cached session on launch (Firebase persists
        // it in Keychain), so returning users skip the Login screen automatically.
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            // Listener may arrive off the main thread → hop before mutating state.
            Task { @MainActor in
                self?.currentUser = user.map {
                    AppUser(id: $0.uid, email: $0.email ?? "", displayName: $0.displayName ?? "")
                }
            }
        }
    }

    // Note: no deinit cleanup needed — AuthService lives for the whole app
    // lifetime (created once at the app root), so the listener is never orphaned.

    // MARK: - Actions

    func signUp(email: String, password: String, displayName: String) async {
        await run {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Set the Firebase display name.
            let change = result.user.createProfileChangeRequest()
            change.displayName = displayName
            try await change.commitChanges()

            // Write the profile document (users/{uid}).
            try await Firestore.firestore()
                .collection("users").document(result.user.uid)
                .setData([
                    "email": email,
                    "displayName": displayName,
                    "createdAt": FieldValue.serverTimestamp(),
                ])

            // Reflect the name locally now (the auth listener already set the rest).
            self.currentUser = AppUser(id: result.user.uid, email: email, displayName: displayName)
        }
    }

    func signIn(email: String, password: String) async {
        await run {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            // The auth-state listener updates currentUser.
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()   // listener fires with nil → back to Login
        } catch {
            errorMessage = "로그아웃에 실패했어요. 다시 시도해주세요."
        }
    }

    // MARK: - Helpers

    /// Wraps an async throwing op with the working flag + Korean error mapping.
    private func run(_ op: @escaping () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await op()
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .invalidEmail:        return "이메일 형식이 올바르지 않아요."
        case .emailAlreadyInUse:   return "이미 가입된 이메일이에요. 로그인해보세요."
        case .weakPassword:        return "비밀번호는 6자 이상이어야 해요."
        case .wrongPassword,
             .invalidCredential:   return "이메일 또는 비밀번호가 올바르지 않아요."
        case .userNotFound:        return "가입되지 않은 이메일이에요. 회원가입해주세요."
        case .networkError:        return "네트워크 연결을 확인해주세요."
        default:                   return "문제가 발생했어요. 잠시 후 다시 시도해주세요."
        }
    }

    // MARK: - Preview

    static var preview: AuthService {
        AuthService(live: false, previewUser: AppUser(id: "preview", email: "test@cardly.app", displayName: "테스터"))
    }
}
