//
//  CardlyApp.swift
//  Cardly
//
//  Created by 윤혜성 on 6/4/26.
//

import SwiftUI
import FirebaseCore

@main
struct CardlyApp: App {
    @State private var auth: AuthService
    @State private var deckStore: DeckStore

    init() {
        // Must run BEFORE any Firebase API (AuthService touches Auth/Firestore).
        FirebaseApp.configure()
        _auth = State(initialValue: AuthService())
        _deckStore = State(initialValue: DeckStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                .environment(deckStore)
        }
    }
}
