//
//  AIService.swift
//  Cardly
//
//  AI abstraction. The app talks to this protocol, never to a concrete API.
//  Today MockAIService returns canned cards after a short delay, so the whole
//  Create → Preview → Save → Study flow works end-to-end and produces real
//  Firestore documents. When a real API is wired later, write e.g.
//  `OpenAIService: AIService` and swap the injected instance — nothing else changes.
//

import Foundation

// MARK: - Shared types

/// Where a deck's source material came from. Persisted on the Deck document.
enum SourceType: String, Codable, CaseIterable {
    case text       // pasted lecture notes
    case pdf        // uploaded PDF (text extracted)
    case prompt     // topic only — AI generates from scratch
}

/// Raw input handed to the generator.
struct AIInput {
    let sourceType: SourceType
    let content: String          // pasted text, extracted PDF text, or a topic
}

/// A pre-save draft card. NOT a Firestore model — the Preview screen edits these,
/// then DeckRepository maps them to persisted `Card` documents on save.
struct CardDraft: Identifiable, Equatable {
    let id = UUID()
    var front: String
    var back: String
    var hint: String? = nil
}

// MARK: - Protocol

protocol AIService {
    /// Generate `count` draft cards from a source. No persistence here.
    func generateCards(from input: AIInput, count: Int) async throws -> [CardDraft]

    /// Per-card "AI 설명 보기" expansion shown during study.
    func explain(front: String, back: String) async throws -> String
}

// MARK: - Mock implementation

/// Returns canned cards after a delay. Stand-in until a real API is wired.
struct MockAIService: AIService {

    /// Canned pool reused for any topic. Cycled/truncated to the requested count.
    private let pool: [CardDraft] = [
        .init(front: "SwiftUI에서 @State와 @Binding의 차이는?",
              back: "@State는 뷰가 직접 소유하는 상태, @Binding은 부모로부터 전달받은 상태에 대한 양방향 참조입니다."),
        .init(front: "ARC가 메모리를 관리하는 원리는?",
              back: "참조 카운트가 0이 되면 객체가 자동으로 해제됩니다."),
        .init(front: "Optional을 unwrapping하는 방법 3가지는?",
              back: "if let, guard let, force unwrap(!) 입니다."),
        .init(front: "Swift의 클래스와 구조체의 핵심 차이는?",
              back: "클래스는 참조 타입, 구조체는 값 타입입니다."),
        .init(front: "weak와 unowned 참조의 차이는?",
              back: "weak는 옵셔널이며 해제 시 nil이 되고, unowned는 비옵셔널이라 해제된 객체 접근 시 크래시합니다."),
        .init(front: "GCD의 main queue와 global queue 차이는?",
              back: "main은 UI 작업용 직렬 큐, global은 백그라운드 작업용 동시 큐입니다."),
        .init(front: "Optional Chaining의 동작 방식은?",
              back: "체인 중 하나라도 nil이면 전체 표현식이 nil을 반환합니다."),
        .init(front: "escaping 클로저란?",
              back: "함수가 반환된 뒤에도 호출될 수 있는 클로저로, @escaping으로 표시합니다."),
    ]

    func generateCards(from input: AIInput, count: Int) async throws -> [CardDraft] {
        // Simulate network/generation latency so the loading UI is exercised.
        try await Task.sleep(for: .seconds(1.5))
        guard count > 0 else { return [] }
        return (0..<count).map { i in
            let base = pool[i % pool.count]
            // Make repeated cards distinct so edits/IDs stay unique.
            let suffix = i >= pool.count ? " (\(i / pool.count + 1))" : ""
            return CardDraft(front: base.front + suffix, back: base.back, hint: base.hint)
        }
    }

    func explain(front: String, back: String) async throws -> String {
        try await Task.sleep(for: .seconds(0.8))
        return "‘\(front)’의 정답이 ‘\(back)’인 이유를 짚어볼게요. 핵심 개념을 한 번 더 떠올리고, "
             + "관련 사례를 함께 묶어 기억하면 다음에 틀리지 않습니다. (실제 AI 설명은 추후 연동 예정)"
    }
}
