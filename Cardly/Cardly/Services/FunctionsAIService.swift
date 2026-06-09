//
//  FunctionsAIService.swift
//  Cardly
//
//  Live AIService backed by Firebase Cloud Functions (Gemini proxy).
//  The API key never touches the client — these callables run server-side and
//  require an authenticated user.
//

import Foundation
import FirebaseFunctions

struct FunctionsAIService: AIService {
    private let functions = Functions.functions(region: "asia-northeast3")

    func generateCards(from input: AIInput, count: Int) async throws -> [CardDraft] {
        let result = try await functions.httpsCallable("generateCards").call([
            "content": input.content,
            "count": count,
            "sourceType": input.sourceType.rawValue,
        ])
        guard let data = result.data as? [String: Any],
              let raw = data["cards"] as? [[String: Any]] else { return [] }
        return raw.compactMap { item in
            guard let front = (item["front"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !front.isEmpty,
                  let back = item["back"] as? String else { return nil }
            let hint = (item["hint"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            return CardDraft(front: front, back: back, hint: hint)
        }
    }

    func explain(front: String, back: String) async throws -> String {
        let result = try await functions.httpsCallable("explainCard").call([
            "front": front,
            "back": back,
        ])
        return (result.data as? [String: Any])?["explanation"] as? String ?? ""
    }
}
