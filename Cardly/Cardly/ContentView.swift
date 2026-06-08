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
    case preview(DraftDeck)
    case study
    case result
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
                        onReview: { path.append(.study) }
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
        case .preview(let draft):
            PreviewView(draft: draft, onBack: pop) { title, cards in
                if await deckStore.createDeck(title: title, sourceType: draft.sourceType, drafts: cards) {
                    path.removeAll()   // back home; live listener shows the new deck
                }
            }
        case .study:
            StudyView(onClose: { path.removeAll() }, onAnswer: { path.append(.result) })
        case .result:
            ResultView(onRetryWrong: { path.append(.study) }, onHome: { path.removeAll() })
        }
    }

    private func pop() { if !path.isEmpty { path.removeLast() } }
}

#Preview {
    ContentView()
        .environment(AuthService.preview)
        .environment(DeckStore.preview)
}
