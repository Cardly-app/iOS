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
}
