//
//  ContentView.swift
//  Cardly
//
//  Root coordinator wiring the 6-screen Cardly flow:
//  Login → Home → Create → Preview → Study → Result
//

import SwiftUI

enum Route: Hashable {
    case create, preview, study, result
}

struct ContentView: View {
    @State private var loggedIn = false
    @State private var path: [Route] = []

    var body: some View {
        if loggedIn {
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
        } else {
            LoginView(onContinue: { loggedIn = true })
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .create:
            CreateView(onBack: pop, onNext: { path.append(.preview) })
        case .preview:
            PreviewView(onBack: pop, onSave: { path.append(.study) })
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
}
