//
//  Models.swift
//  Cardly
//
//  Firestore-backed Codable models. Dates use `Date` (the SDK maps them to
//  Firestore Timestamp automatically). `@DocumentID` is filled in on read and
//  left nil on create (Firestore assigns the id).
//
//  NOTE: `Flashcard`, `CreateOption`, and `SampleData` (previewCards/wrongCards)
//  still back the not-yet-converted Preview/Study/Result screens. They'll be
//  removed once those screens read real data (week 4 of the plan).
//

import Foundation
import FirebaseFirestore

// MARK: - Firestore models

/// users/{uid}/decks/{deckId}
struct Deck: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var title: String
    var description: String = ""
    var sourceType: SourceType = .prompt
    var createdAt: Date = Date()
    var cardCount: Int = 0

    /// UI-only color tone, derived deterministically from the id (not persisted).
    /// Uses a stable scalar sum — Swift's `hashValue` is randomized per launch.
    var tone: Tone {
        let key = id ?? title
        let sum = key.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Tone.allCases[sum % Tone.allCases.count]
    }
}

/// users/{uid}/decks/{deckId}/cards/{cardId}
struct Card: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var deckId: String? = nil      // denormalized so a loaded card can be updated
    var front: String
    var back: String
    var hint: String? = nil
    var createdAt: Date = Date()
    var lastReviewedAt: Date? = nil
    var nextReviewAt: Date = Date()
    var correctCount: Int = 0
    var wrongCount: Int = 0
    var lastResult: CardResult? = nil
    var streak: Int = 0
}

enum CardResult: String, Codable, Hashable { case correct, wrong }

/// Result of one study session, carried Study → Result (Hashable for the Route).
struct StudySummary: Hashable {
    var total: Int
    var correct: Int
    var elapsedSeconds: Int
    var wrong: [Card]

    var pct: Int { total == 0 ? 0 : Int((Double(correct) / Double(total) * 100).rounded()) }
}

/// users/{uid}/sessions/{sessionId}
struct StudySessionRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var deckId: String
    var startedAt: Date
    var endedAt: Date
    var totalCards: Int
    var correctCards: Int
}

// MARK: - UI-only metadata (kept)

struct CreateOption: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let subtitle: String
    let tone: Tone
    var ai: Bool = false
}

/// Pre-save result of generation, carried Create → Preview → save.
/// Hashable so it can ride inside the navigation Route (avoids a state race).
struct DraftDeck: Hashable {
    var title: String
    var sourceType: SourceType
    var drafts: [CardDraft]
}

// MARK: - UI-only metadata for the create screen

enum SampleData {
    static let createOptions: [CreateOption] = [
        .init(symbol: "text.alignleft", title: "텍스트 붙여넣기", subtitle: "강의노트나 정리 자료를 직접 입력", tone: .lav),
        .init(symbol: "doc", title: "PDF 업로드", subtitle: "강의 슬라이드나 교재 PDF를 업로드", tone: .sky),
        .init(symbol: "sparkles", title: "주제로 시작", subtitle: "주제만 입력하면 AI가 카드를 생성", tone: .lime, ai: true),
    ]
}
