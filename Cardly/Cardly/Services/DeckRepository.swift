//
//  DeckRepository.swift
//  Cardly
//
//  All Firestore reads/writes under users/{uid}. Stateless — the observable
//  DeckStore owns the live data; this type just talks to Firestore.
//

import Foundation
import FirebaseFirestore

struct DeckRepository {
    private var db: Firestore { Firestore.firestore() }

    private func decksRef(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("decks")
    }
    private func cardsRef(_ uid: String, _ deckId: String) -> CollectionReference {
        decksRef(uid).document(deckId).collection("cards")
    }

    // MARK: - Reads

    /// Live listener over the user's decks (newest first). Returns the
    /// registration so the caller can detach it on sign-out.
    func decksListener(uid: String, onChange: @escaping ([Deck]) -> Void) -> ListenerRegistration {
        decksRef(uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let decks = snapshot?.documents.compactMap { try? $0.data(as: Deck.self) } ?? []
                onChange(decks)
            }
    }

    /// One-shot read of all cards in a deck.
    func cards(uid: String, deckId: String) async throws -> [Card] {
        let snap = try await cardsRef(uid, deckId)
            .order(by: "createdAt", descending: false)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: Card.self) }
    }

    /// Cards due for review (nextReviewAt <= now) across the given decks,
    /// soonest first. One per-deck query (single-field filter — no composite
    /// index needed); fine for the modest deck counts in this app.
    func dueCards(uid: String, deckIds: [String], now: Date = Date()) async throws -> [Card] {
        var all: [Card] = []
        for deckId in deckIds {
            let snap = try await cardsRef(uid, deckId)
                .whereField("nextReviewAt", isLessThanOrEqualTo: Timestamp(date: now))
                .getDocuments()
            all += snap.documents.compactMap { try? $0.data(as: Card.self) }
        }
        return all.sorted { $0.nextReviewAt < $1.nextReviewAt }
    }

    // MARK: - Writes

    /// Creates a deck and all its cards in one batch. New cards are due
    /// immediately (nextReviewAt = now). Returns the new deck id.
    /// Uses plain dictionaries (not Codable `setData(from:)`) for robustness.
    @discardableResult
    func createDeck(uid: String, title: String, sourceType: SourceType,
                    drafts: [CardDraft], now: Date = Date()) async throws -> String {
        let deckRef = decksRef(uid).document()          // pre-generate id
        let batch = db.batch()
        let ts = Timestamp(date: now)

        batch.setData([
            "title": title,
            "description": "",
            "sourceType": sourceType.rawValue,
            "createdAt": ts,
            "cardCount": drafts.count,
        ], forDocument: deckRef)

        let cards = cardsRef(uid, deckRef.documentID)
        for d in drafts {
            var data: [String: Any] = [
                "deckId": deckRef.documentID,
                "front": d.front,
                "back": d.back,
                "createdAt": ts,
                "nextReviewAt": ts,
                "correctCount": 0,
                "wrongCount": 0,
                "streak": 0,
            ]
            if let hint = d.hint { data["hint"] = hint }
            batch.setData(data, forDocument: cards.document())
        }

        try await batch.commit()
        return deckRef.documentID
    }

    /// Update one card's scheduling fields after an answer.
    func recordAnswer(uid: String, deckId: String, cardId: String,
                      nextReviewAt: Date, streak: Int, result: CardResult,
                      now: Date = Date()) async throws {
        try await cardsRef(uid, deckId).document(cardId).updateData([
            "nextReviewAt": Timestamp(date: nextReviewAt),
            "lastReviewedAt": Timestamp(date: now),
            "lastResult": result.rawValue,
            "streak": streak,
            "correctCount": FieldValue.increment(Int64(result == .correct ? 1 : 0)),
            "wrongCount": FieldValue.increment(Int64(result == .wrong ? 1 : 0)),
        ])
    }

    /// Delete a deck and all of its cards. Firestore doesn't cascade, so we
    /// remove the cards subcollection in a batch, then the deck document.
    func deleteDeck(uid: String, deckId: String) async throws {
        let cardSnap = try await cardsRef(uid, deckId).getDocuments()
        let batch = db.batch()
        for doc in cardSnap.documents { batch.deleteDocument(doc.reference) }
        batch.deleteDocument(decksRef(uid).document(deckId))
        try await batch.commit()
    }

    /// All finished sessions, newest first (for the stats tab).
    func sessions(uid: String) async throws -> [StudySessionRecord] {
        let snap = try await db.collection("users").document(uid).collection("sessions")
            .order(by: "startedAt", descending: true)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: StudySessionRecord.self) }
    }

    /// Append a finished-session summary document.
    func writeSession(uid: String, deckId: String, startedAt: Date, endedAt: Date,
                      totalCards: Int, correctCards: Int) async throws {
        try await db.collection("users").document(uid).collection("sessions").addDocument(data: [
            "deckId": deckId,
            "startedAt": Timestamp(date: startedAt),
            "endedAt": Timestamp(date: endedAt),
            "totalCards": totalCards,
            "correctCards": correctCards,
        ])
    }
}
