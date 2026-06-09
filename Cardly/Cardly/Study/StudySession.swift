//
//  StudySession.swift
//  Cardly
//
//  One study run over a preloaded set of cards. Records each answer to Firestore
//  (scheduling the next review), then writes a session summary on finish.
//  A stable @MainActor class so the async Firestore calls capture a fixed context.
//

import Foundation

@MainActor
@Observable
final class StudySession {
    let cards: [Card]
    private(set) var index = 0
    private(set) var isRevealed = false
    private(set) var correctCount = 0
    private(set) var wrong: [Card] = []

    private let uid: String
    private let repo: DeckRepository
    private let startedAt: Date

    /// Spaced-repetition ladder for consecutive correct answers (days).
    private let ladder: [TimeInterval] = [1, 3, 7, 14, 30].map { $0 * 86_400 }
    private let wrongDelay: TimeInterval = 10 * 60   // 10 minutes

    init(cards: [Card], uid: String,
         repo: DeckRepository = DeckRepository(),
         startedAt: Date = Date()) {
        self.cards = cards
        self.uid = uid
        self.repo = repo
        self.startedAt = startedAt
    }

    var currentCard: Card? { index < cards.count ? cards[index] : nil }
    var progress: Double { cards.isEmpty ? 0 : Double(index) / Double(cards.count) }
    var positionText: String { "\(min(index + 1, cards.count)) / \(cards.count)" }
    var isFinished: Bool { index >= cards.count }

    func reveal() { isRevealed = true }

    /// Grade the current card, schedule its next review, persist, and advance.
    func answer(_ result: CardResult) async {
        guard let card = currentCard else { return }
        var streak = card.streak
        let next: Date
        switch result {
        case .correct:
            streak += 1
            next = Date().addingTimeInterval(ladder[min(streak - 1, ladder.count - 1)])
            correctCount += 1
        case .wrong:
            streak = 0
            next = Date().addingTimeInterval(wrongDelay)
            wrong.append(card)
        }

        if let deckId = card.deckId, let cardId = card.id {
            try? await repo.recordAnswer(uid: uid, deckId: deckId, cardId: cardId,
                                         nextReviewAt: next, streak: streak, result: result)
        }

        isRevealed = false
        index += 1
    }

    /// Write the session record and return the summary for the result screen.
    func finish() async -> StudySummary {
        let ended = Date()
        let deckId = cards.first?.deckId ?? ""
        try? await repo.writeSession(uid: uid, deckId: deckId,
                                     startedAt: startedAt, endedAt: ended,
                                     totalCards: cards.count, correctCards: correctCount)
        return StudySummary(total: cards.count, correct: correctCount,
                            elapsedSeconds: Int(ended.timeIntervalSince(startedAt)),
                            wrong: wrong)
    }
}
