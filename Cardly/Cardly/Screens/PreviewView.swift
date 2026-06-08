//
//  PreviewView.swift
//  Cardly — Screen 4: Preview generated cards, edit, and save to Firestore
//

import SwiftUI

struct PreviewView: View {
    let draft: DraftDeck
    var onBack: () -> Void = {}
    var onSave: @MainActor (_ title: String, _ cards: [CardDraft]) async -> Void = { _, _ in }

    @State private var title: String
    @State private var cards: [CardDraft]
    @State private var saving = false

    init(draft: DraftDeck,
         onBack: @escaping () -> Void = {},
         onSave: @escaping @MainActor (_ title: String, _ cards: [CardDraft]) async -> Void = { _, _ in }) {
        self.draft = draft
        self.onBack = onBack
        self.onSave = onSave
        _title = State(initialValue: draft.title)
        _cards = State(initialValue: draft.drafts)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bgSoft.ignoresSafeArea()

            VStack(spacing: 0) {
                NavBar(title: "미리보기", onBack: onBack)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // success banner
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Theme.primary, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("카드 \(cards.count)장이 생성됐어요")
                                    .font(.pretendard(15.5, weight: .bold)).kerning(-0.3)
                                    .foregroundStyle(Theme.primaryInk).lineLimit(1)
                                Text("확인하고 필요하면 편집하세요")
                                    .font(.pretendard(13, weight: .medium))
                                    .foregroundStyle(Theme.primaryInk.opacity(0.7)).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(Theme.lav, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        // editable title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("덱 이름")
                                .font(.pretendard(11, weight: .bold)).kerning(0.4)
                                .textCase(.uppercase).foregroundStyle(Theme.ink2)
                            TextField("덱 이름", text: $title)
                                .font(.pretendard(17, weight: .bold))
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .cardStyle(soft: true)
                        .padding(.top, 16)

                        HStack {
                            Text("생성된 카드").font(.pretendard(15, weight: .bold)).kerning(-0.3)
                            Spacer()
                            Text("\(cards.count)장").font(.pretendard(13, weight: .semibold)).foregroundStyle(Theme.ink2)
                        }
                        .padding(.horizontal, 2).padding(.top, 22).padding(.bottom, 12)

                        VStack(spacing: 12) {
                            ForEach(cards) { card in
                                PreviewCard(c: card) { delete(card) }
                            }
                        }
                        .padding(.bottom, 110)
                    }
                    .padding(.horizontal, 20).padding(.top, 6)
                }
            }

            PillButton(title: saving ? "저장 중…" : "덱 저장하기",
                       style: canSave ? .primary : .disabled) {
                Task { @MainActor in
                    saving = true
                    await onSave(finalTitle, cards)
                    saving = false
                }
            }
            .disabled(!canSave || saving)
            .overlay { if saving { ProgressView().tint(.white) } }
            .dock(soft: true)
        }
    }

    private var finalTitle: String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "새 덱" : t
    }
    private var canSave: Bool { !cards.isEmpty }

    private func delete(_ card: CardDraft) {
        cards.removeAll { $0.id == card.id }
    }
}

struct PreviewCard: View {
    let c: CardDraft
    var onDelete: () -> Void = {}
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 9) {
                qaBadge("Q", fg: Theme.primary, bg: Theme.lav)
                Text(c.front).font(.pretendard(15, weight: .bold)).kerning(-0.3).lineSpacing(2)
                Spacer(minLength: 0)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .regular)).foregroundStyle(Theme.ink3)
                }.buttonStyle(.plain)
            }
            HStack(alignment: .top, spacing: 9) {
                qaBadge("A", fg: Theme.ink2, bg: Theme.bgSoft)
                Text(c.back).font(.pretendard(14, weight: .medium)).foregroundStyle(Theme.ink2).lineSpacing(2)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func qaBadge(_ t: String, fg: Color, bg: Color) -> some View {
        Text(t).font(.pretendard(11, weight: .heavy)).foregroundStyle(fg)
            .frame(width: 20, height: 20)
            .background(bg, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview {
    PreviewView(draft: DraftDeck(title: "iOS 프로그래밍 기말", sourceType: .prompt, drafts: [
        CardDraft(front: "SwiftUI에서 @State와 @Binding의 차이는?", back: "@State는 뷰 소유, @Binding은 부모로부터의 양방향 참조."),
        CardDraft(front: "ARC의 동작 원리는?", back: "참조 카운트가 0이 되면 해제."),
    ]))
}
