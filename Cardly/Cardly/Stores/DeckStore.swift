//
//  DeckStore.swift
//  Cardly
//
//  Observable live view of the signed-in user's decks. ContentView binds it to
//  the current uid; it (re)subscribes to the Firestore listener and tears down
//  on sign-out so no listener fires against an unauthorized path.
//

import Foundation
import FirebaseFirestore

@MainActor
@Observable
final class DeckStore {
    private(set) var decks: [Deck] = []
    private(set) var isLoading = false

    /// Cards due for review today, across all decks. Wired in week 4 (study
    /// scheduling). For now derived as 0 until cards carry review state.
    var dueCount: Int = 0

    private let repo = DeckRepository()
    private var listener: ListenerRegistration?
    private var boundUid: String?

    /// Attach (or detach when uid == nil) the live decks listener. Safe to call
    /// repeatedly — no-ops if already bound to the same uid.
    func bind(uid: String?) {
        guard uid != boundUid else { return }
        listener?.remove()
        listener = nil
        decks = []
        dueCount = 0
        boundUid = uid

        guard let uid else { return }
        isLoading = true
        listener = repo.decksListener(uid: uid) { [weak self] decks in
            Task { @MainActor in
                guard let self else { return }
                self.decks = decks
                self.isLoading = false
                await self.refreshDueCount()
            }
        }
    }

    /// Cards due for review right now, across all of the user's decks.
    func loadDueCards() async -> [Card] {
        guard let uid = boundUid else { return [] }
        let ids = decks.compactMap { $0.id }
        return (try? await repo.dueCards(uid: uid, deckIds: ids)) ?? []
    }

    /// Recompute the "오늘의 복습" badge count. Call after a study session
    /// (card scheduling changes don't trigger the decks listener).
    func refreshDueCount() async {
        dueCount = await loadDueCards().count
    }

    /// Delete a deck (and its cards). The decks listener updates the list;
    /// we also refresh the due count since the deck's cards are gone.
    func deleteDeck(_ deck: Deck) async {
        guard let uid = boundUid, let deckId = deck.id else { return }
        do {
            try await repo.deleteDeck(uid: uid, deckId: deckId)
            await refreshDueCount()
        } catch {
            print("deleteDeck failed:", error)
        }
    }

    /// Create a deck for the currently-bound user. Returns true on success.
    /// Lives here (a stable @MainActor class) rather than in a View struct so
    /// the async Firestore call doesn't capture a transient struct context.
    @discardableResult
    func createDeck(title: String, sourceType: SourceType, drafts: [CardDraft]) async -> Bool {
        guard let uid = boundUid else { return false }
        do {
            try await repo.createDeck(uid: uid, title: title, sourceType: sourceType, drafts: drafts)
            return true
        } catch {
            print("createDeck failed:", error)
            return false
        }
    }

    // MARK: - Preview

    init() {}

    init(previewDecks: [Deck]) { decks = previewDecks }

    static var preview: DeckStore {
        DeckStore(previewDecks: [
            Deck(id: "1", title: "iOS 프로그래밍 기말", sourceType: .pdf, cardCount: 45),
            Deck(id: "2", title: "웹프레임워크2 퀴즈", sourceType: .text, cardCount: 32),
            Deck(id: "3", title: "운영체제 중간고사", sourceType: .prompt, cardCount: 28),
        ])
    }
}
