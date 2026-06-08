//
//  ContentView.swift
//  Cardly
//
//  Root coordinator wiring the 6-screen Cardly flow:
//  Login → Home → Create → Preview → Study → Result
//

import SwiftUI

enum Route: Hashable {
    case create
    case deckDetail(Deck)
    case preview(DraftDeck)
    case study([Card])
    case result(StudySummary)
}

struct ContentView: View {
    @Environment(AuthService.self) private var auth
    @Environment(DeckStore.self) private var deckStore
    @State private var path: [Route] = []

    var body: some View {
        Group {
            if auth.currentUser == nil {
                LoginView()
            } else {
                NavigationStack(path: $path) {
                    MainTabView(
                        onCreate: { path.append(.create) },
                        onReview: startReview
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: Route.self) { route in
                        destination(route)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
                .tint(Theme.primary)
            }
        }
        // Keep the live decks listener in sync with the signed-in user.
        .task(id: auth.currentUser?.id) {
            deckStore.bind(uid: auth.currentUser?.id)
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .create:
            CreateView(onBack: pop, onGenerated: { d in path.append(.preview(d)) })
        case .deckDetail(let deck):
            DeckDetailView(deck: deck, onBack: pop, onStudy: { cards in
                if !cards.isEmpty { path.append(.study(cards)) }
            })
        case .preview(let draft):
            PreviewView(draft: draft, onBack: pop) { title, cards in
                if await deckStore.createDeck(title: title, sourceType: draft.sourceType, drafts: cards) {
                    path.removeAll()   // back home; live listener shows the new deck
                }
            }
        case .study(let cards):
            StudyView(cards: cards, uid: auth.currentUser?.id ?? "",
                      onClose: { path.removeAll() },
                      onFinish: { summary in
                          path.append(.result(summary))
                          Task { await deckStore.refreshDueCount() }
                      })
        case .result(let summary):
            ResultView(summary: summary,
                       onRetryWrong: { wrong in path.append(.study(wrong)) },
                       onHome: { path.removeAll() })
        }
    }

    /// Load today's due cards and start a study session (no-op if none due).
    private func startReview() {
        Task {
            let due = await deckStore.loadDueCards()
            if !due.isEmpty { path.append(.study(due)) }
        }
    }

    private func pop() { if !path.isEmpty { path.removeLast() } }
}

#Preview {
    ContentView()
        .environment(AuthService.preview)
        .environment(DeckStore.preview)
}
