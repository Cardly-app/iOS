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
    @State private var cardToDelete: Card?
    @State private var cardToEdit: Card?
    @State private var renamedTitle: String?
    @State private var showRename = false
    @State private var renameText = ""

    private var title: String { renamedTitle ?? deck.title }

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
                                    Text(title).font(.pretendard(20, weight: .heavy)).kerning(-0.5)
                                        .lineLimit(2)
                                    Text("카드 \(loading ? deck.cardCount : cards.count)장")
                                        .font(.pretendard(13.5, weight: .medium)).foregroundStyle(Theme.ink2)
                                }
                                Spacer(minLength: 0)
                                Button {
                                    renameText = title
                                    showRename = true
                                } label: {
                                    Image(systemName: "pencil").font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Theme.ink3)
                                        .frame(width: 32, height: 32)
                                }
                                .buttonStyle(.plain)
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
                                ForEach(cards) { card in
                                    CardCell(card: card,
                                             onEdit: { cardToEdit = card },
                                             onDelete: { cardToDelete = card })
                                }
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
        .confirmationDialog("이 카드를 삭제할까요?",
            isPresented: Binding(get: { cardToDelete != nil },
                                 set: { if !$0 { cardToDelete = nil } }),
            presenting: cardToDelete) { card in
            Button("삭제", role: .destructive) { Task { await delete(card) } }
            Button("취소", role: .cancel) {}
        }
        .sheet(item: $cardToEdit) { card in
            CardEditView(card: card) { front, back in
                await edit(card, front: front, back: back)
            }
        }
        .alert("덱 이름 수정", isPresented: $showRename) {
            TextField("덱 이름", text: $renameText)
            Button("저장") { Task { await rename() } }
            Button("취소", role: .cancel) {}
        }
    }

    private func delete(_ card: Card) async {
        guard let deckId = deck.id, let cardId = card.id else { return }
        if await deckStore.deleteCard(deckId: deckId, cardId: cardId) {
            cards.removeAll { $0.id == card.id }
        }
    }

    private func edit(_ card: Card, front: String, back: String) async {
        guard let deckId = deck.id, let cardId = card.id, !front.isEmpty, !back.isEmpty else { return }
        if await deckStore.updateCard(deckId: deckId, cardId: cardId, front: front, back: back),
           let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx].front = front
            cards[idx].back = back
        }
    }

    private func rename() async {
        let t = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let deckId = deck.id else { return }
        if await deckStore.renameDeck(deckId: deckId, title: t) {
            renamedTitle = t
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
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 10) {
                badge("Q", fg: Theme.primary, bg: Theme.lav)
                Text(card.front).font(.pretendard(15, weight: .bold)).kerning(-0.3).lineSpacing(2)
                Spacer(minLength: 0)
                if card.correctCount + card.wrongCount > 0 {
                    Text("\(card.correctCount)✓ \(card.wrongCount)✗")
                        .font(.pretendard(11.5, weight: .bold)).monospacedDigit()
                        .foregroundStyle(Theme.ink3)
                }
                Button(action: onDelete) {
                    Image(systemName: "trash").font(.system(size: 14))
                        .foregroundStyle(Theme.ink3)
                }
                .buttonStyle(.plain)
            }
            HStack(alignment: .top, spacing: 9) {
                badge("A", fg: Theme.ink2, bg: Theme.bgSoft)
                Text(card.back).font(.pretendard(14, weight: .medium)).foregroundStyle(Theme.ink2).lineSpacing(2)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
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
