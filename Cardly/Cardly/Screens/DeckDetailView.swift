//
//  DeckDetailView.swift
//  Cardly — a single deck: its cards + study entry point
//

import SwiftUI

struct DeckDetailView: View {
    let deck: Deck
    var onBack: () -> Void = {}
    var onStudy: ([Card]) -> Void = { _ in }

    @Environment(DeckStore.self) private var deckStore
    @State private var cards: [Card] = []
    @State private var loading = true

    private var dueCount: Int {
        let now = Date()
        return cards.filter { $0.nextReviewAt <= now }.count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bgSoft.ignoresSafeArea()

            VStack(spacing: 0) {
                NavBar(title: "덱", backLabel: "뒤로", onBack: onBack)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // header card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15, style: .continuous).fill(deck.tone.fill)
                                    Image(systemName: "rectangle.on.rectangle")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(deck.tone.ink)
                                }
                                .frame(width: 56, height: 56)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(deck.title).font(.pretendard(20, weight: .heavy)).kerning(-0.5)
                                        .lineLimit(2)
                                    Text("카드 \(deck.cardCount)장")
                                        .font(.pretendard(13.5, weight: .medium)).foregroundStyle(Theme.ink2)
                                }
                                Spacer(minLength: 0)
                            }

                            HStack(spacing: 10) {
                                miniStat("복습 예정", "\(dueCount)장", Theme.lav, Theme.lavInk)
                                miniStat("전체 카드", "\(cards.count)장", Theme.sky, Theme.skyInk)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle(soft: true)

                        Text("카드 목록")
                            .font(.pretendard(15, weight: .bold)).kerning(-0.3)
                            .padding(.horizontal, 2).padding(.top, 24).padding(.bottom, 12)

                        if loading {
                            ProgressView().frame(maxWidth: .infinity).padding(.top, 30)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(cards) { CardCell(card: $0) }
                            }
                        }
                        Color.clear.frame(height: 110)
                    }
                    .padding(.horizontal, 20).padding(.top, 6)
                }
            }

            PillButton(title: cards.isEmpty ? "카드 없음" : "이 덱 학습하기",
                       style: cards.isEmpty ? .disabled : .primary) {
                onStudy(cards)
            }
            .disabled(cards.isEmpty)
            .dock(soft: true)
        }
        .task {
            cards = await deckStore.cards(in: deck)
            loading = false
        }
    }

    private func miniStat(_ l: String, _ v: String, _ fill: Color, _ ink: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(l).font(.pretendard(12, weight: .bold)).foregroundStyle(ink.opacity(0.8))
            Text(v).font(.pretendard(20, weight: .heavy)).kerning(-0.5).foregroundStyle(ink)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CardCell: View {
    let card: Card
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 9) {
                badge("Q", fg: Theme.primary, bg: Theme.lav)
                Text(card.front).font(.pretendard(15, weight: .bold)).kerning(-0.3).lineSpacing(2)
                Spacer(minLength: 0)
                if card.correctCount + card.wrongCount > 0 {
                    Text("\(card.correctCount)✓ \(card.wrongCount)✗")
                        .font(.pretendard(11.5, weight: .bold)).monospacedDigit()
                        .foregroundStyle(Theme.ink3)
                }
            }
            HStack(alignment: .top, spacing: 9) {
                badge("A", fg: Theme.ink2, bg: Theme.bgSoft)
                Text(card.back).font(.pretendard(14, weight: .medium)).foregroundStyle(Theme.ink2).lineSpacing(2)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func badge(_ t: String, fg: Color, bg: Color) -> some View {
        Text(t).font(.pretendard(11, weight: .heavy)).foregroundStyle(fg)
            .frame(width: 20, height: 20)
            .background(bg, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview {
    DeckDetailView(deck: Deck(id: "1", title: "iOS 프로그래밍 기말", sourceType: .pdf, cardCount: 20))
        .environment(DeckStore.preview)
}
