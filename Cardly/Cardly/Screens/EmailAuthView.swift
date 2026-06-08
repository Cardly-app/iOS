//
//  EmailAuthView.swift
//  Cardly — email/password sign in + sign up (presented as a sheet from Login)
//

import SwiftUI

struct EmailAuthView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss

    private enum Mode { case signIn, signUp }
    @State private var mode: Mode = .signIn
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focused: Field?
    private enum Field { case name, email, password }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(mode == .signIn ? "다시 오셨네요" : "Cardly 시작하기")
                    .font(.pretendard(27, weight: .heavy)).kerning(-0.8)
                Text(mode == .signIn ? "이메일로 로그인하세요." : "이메일로 계정을 만드세요.")
                    .font(.pretendard(15, weight: .medium)).foregroundStyle(Theme.ink2)
                    .padding(.top, 6)

                VStack(spacing: 12) {
                    if mode == .signUp {
                        field("이름", text: $name, field: .name)
                            .textContentType(.name)
                            .submitLabel(.next)
                    }
                    field("이메일", text: $email, field: .email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    field("비밀번호 (6자 이상)", text: $password, field: .password, secure: true)
                        .textContentType(mode == .signIn ? .password : .newPassword)
                        .submitLabel(.go)
                }
                .padding(.top, 24)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.pretendard(13.5, weight: .semibold))
                        .foregroundStyle(Theme.coral)
                        .padding(.top, 12)
                }

                PillButton(title: mode == .signIn ? "로그인" : "회원가입",
                           style: canSubmit ? .primary : .disabled) {
                    Task { await submit() }
                }
                .disabled(!canSubmit || auth.isWorking)
                .overlay { if auth.isWorking { ProgressView().tint(.white) } }
                .padding(.top, 22)

                Button {
                    withAnimation { mode = (mode == .signIn ? .signUp : .signIn) }
                } label: {
                    Text(mode == .signIn ? "계정이 없으신가요?  회원가입" : "이미 계정이 있으신가요?  로그인")
                        .font(.pretendard(14, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(.top, 18)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
        .background(Theme.bg)
        .onSubmit(advanceFocus)
    }

    private var canSubmit: Bool {
        let base = email.contains("@") && password.count >= 6
        return mode == .signIn ? base : base && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() async {
        focused = nil
        switch mode {
        case .signIn: await auth.signIn(email: email, password: password)
        case .signUp: await auth.signUp(email: email, password: password,
                                        displayName: name.trimmingCharacters(in: .whitespaces))
        }
        // On success the auth listener flips currentUser and ContentView swaps
        // away from Login, taking this sheet with it. Nothing else to do.
    }

    private func advanceFocus() {
        switch focused {
        case .name: focused = .email
        case .email: focused = .password
        default: Task { await submit() }
        }
    }

    @ViewBuilder
    private func field(_ placeholder: String, text: Binding<String>, field: Field, secure: Bool = false) -> some View {
        Group {
            if secure { SecureField(placeholder, text: text) }
            else { TextField(placeholder, text: text) }
        }
        .font(.pretendard(16, weight: .medium))
        .focused($focused, equals: field)
        .padding(.horizontal, 16).padding(.vertical, 15)
        .background(Theme.bgSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(focused == field ? Theme.primary : Color.clear, lineWidth: 1.5)
        )
    }
}

#Preview {
    EmailAuthView()
        .environment(AuthService.preview)
}
