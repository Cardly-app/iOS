//
//  StudyView.swift
//  Cardly — Screen 5: Study (real card-by-card session)
//

import SwiftUI

struct StudyView: View {
    var onClose: () -> Void = {}
    var onFinish: @MainActor (StudySummary) -> Void = { _ in }

    @State private var session: StudySession
    @State private var working = false

    init(cards: [Card], uid: String,
         onClose: @escaping () -> Void = {},
         onFinish: @escaping @MainActor (StudySummary) -> Void = { _ in }) {
        self.onClose = onClose
        self.onFinish = onFinish
        _session = State(initialValue: StudySession(cards: cards, uid: uid))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bgSoft.ignoresSafeArea()

            VStack(spacing: 0) {
                // progress header
                HStack(spacing: 14) {
                    Button(action: onClose) {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    }.buttonStyle(.plain)
                    ProgressTrack(pct: session.progress * 100, height: 7)
                    Text(session.positionText)
                        .font(.pretendard(13.5, weight: .bold)).foregroundStyle(Theme.ink2)
                        .monospacedDigit().frame(minWidth: 52, alignment: .trailing)
                }
                .padding(.horizontal, 20).padding(.top, 4)

                if let card = session.currentCard {
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white)
                            .frame(height: 40).opacity(0.6)
                            .padding(.horizontal, 34).offset(y: 18)
                            .shadow(color: Color(hex: "#1C1B28").opacity(0.05), radius: 10, y: 2)
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white)
                            .frame(height: 40).opacity(0.8)
                            .padding(.horizontal, 27).offset(y: 24)
                            .shadow(color: Color(hex: "#1C1B28").opacity(0.05), radius: 10, y: 2)

                        cardFace(card)
                    }
                    .padding(.horizontal, 20).padding(.top, 28)
                    .id(card.id)   // animate transition between cards
                }

                Spacer()
            }

            HStack(spacing: 11) {
                PillButton(title: "다시 볼래요", style: .coralOutline) { answer(.wrong) }
                PillButton(title: "외웠어요", style: .green) { answer(.correct) }
            }
            .opacity(session.isRevealed ? 1 : 0.4)
            .disabled(!session.isRevealed || working)
            .dock(soft: true)
        }
    }

    @ViewBuilder
    private func cardFace(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("질문", color: Theme.ink2)
            Text(card.front)
                .font(.pretendard(23, weight: .bold)).kerning(-0.5).lineSpacing(5)
                .padding(.top, 8)

            if session.isRevealed {
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 20)

                eyebrow("정답", color: Theme.primary)
                Text(card.back)
                    .font(.pretendard(16, weight: .medium)).lineSpacing(6)
                    .padding(.top, 8)
            } else {
                Button { session.reveal() } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "hand.tap").font(.system(size: 14))
                        Text("탭하면 정답 보기").font(.pretendard(13.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.ink2)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .overlay(Capsule().stroke(Theme.line2, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 18)
            }
        }
        .padding(EdgeInsets(top: 26, leading: 22, bottom: 24, trailing: 22))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "#28265A").opacity(0.18), radius: 40, x: 0, y: 14)
        .contentShape(Rectangle())
        .onTapGesture { if !session.isRevealed { session.reveal() } }
    }

    private func answer(_ result: CardResult) {
        guard !working else { return }
        working = true
        Task { @MainActor in
            await session.answer(result)
            if session.isFinished {
                let summary = await session.finish()
                onFinish(summary)
            }
            working = false
        }
    }

    private func eyebrow(_ t: String, color: Color) -> some View {
        Text(t).font(.pretendard(12, weight: .bold)).kerning(0.4)
            .textCase(.uppercase).foregroundStyle(color)
    }
}

#Preview {
    StudyView(cards: [
        Card(deckId: "d", front: "SwiftUI에서 @State와 @Binding의 차이는?",
             back: "@State는 뷰가 소유, @Binding은 부모로부터의 양방향 참조."),
        Card(deckId: "d", front: "ARC의 동작 원리는?", back: "참조 카운트가 0이면 해제."),
    ], uid: "preview")
}
