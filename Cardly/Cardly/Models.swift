//
//  Models.swift
//  Cardly
//
//  Sample data backing the static design.
//

import Foundation

struct Deck: Identifiable {
    let id = UUID()
    let name: String
    let meta: String
    let pct: Double
    let tone: Tone
}

struct Flashcard: Identifiable {
    let id = UUID()
    let q: String
    let a: String
}

struct CreateOption: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let subtitle: String
    let tone: Tone
    var ai: Bool = false
}

enum SampleData {
    static let decks: [Deck] = [
        .init(name: "iOS 프로그래밍 기말", meta: "카드 45장 · 어제 학습", pct: 78, tone: .lav),
        .init(name: "웹프레임워크2 퀴즈", meta: "카드 32장 · 3일 전 학습", pct: 65, tone: .sky),
        .init(name: "운영체제 중간고사", meta: "카드 28장 · 1주일 전 학습", pct: 82, tone: .lime),
    ]

    static let createOptions: [CreateOption] = [
        .init(symbol: "text.alignleft", title: "텍스트 붙여넣기", subtitle: "강의노트나 정리 자료를 직접 입력", tone: .lav),
        .init(symbol: "doc", title: "PDF 업로드", subtitle: "강의 슬라이드나 교재 PDF를 업로드", tone: .sky),
        .init(symbol: "sparkles", title: "주제로 시작", subtitle: "주제만 입력하면 AI가 카드를 생성", tone: .lime, ai: true),
    ]

    static let previewCards: [Flashcard] = [
        .init(q: "SwiftUI에서 @State와 @Binding의 차이는?", a: "@State는 뷰 자체의 상태를, @Binding은 부모…"),
        .init(q: "ARC가 메모리를 관리하는 원리는?", a: "참조 카운트가 0이 되면 자동으로 해제…"),
        .init(q: "Optional의 unwrapping 방법 3가지는?", a: "if let, guard let, force unwrap (!)"),
        .init(q: "Swift의 클래스와 구조체의 핵심 차이는?", a: "클래스는 참조 타입, 구조체는 값 타입…"),
    ]

    static let wrongCards: [String] = [
        "Optional Chaining의 동작 방식은?",
        "GCD의 main / global queue 차이?",
        "weak와 unowned 참조의 차이는?",
    ]
}
