//
//  ResultView.swift
//  Cardly — Screen 6: Result (real session summary)
//

import SwiftUI

struct ResultView: View {
    let summary: StudySummary
    var onRetryWrong: ([Card]) -> Void = { _ in }
    var onHome: () -> Void = {}
    @AppStorage("reviewReminderOn") private var reminderOn = false

    private var elapsedText: String {
        let m = summary.elapsedSeconds / 60, s = summary.elapsedSeconds % 60
        return m > 0 ? "\(m)분" : "\(s)초"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bgSoft.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Pill(text: "세션 완료", systemImage: "party.popper.fill", fill: Theme.lime, fg: Theme.limeInk)

                    // donut
                    ZStack {
                        Donut(pct: Double(summary.pct), size: 172)
                        VStack(spacing: 2) {
                            Text("\(summary.pct)%").font(.pretendard(44, weight: .heavy)).kerning(-2).monospacedDigit()
                            Text("\(summary.correct) / \(summary.total) 정답")
                                .font(.pretendard(13.5, weight: .semibold)).foregroundStyle(Theme.ink2)
                                .monospacedDigit()
                        }
                    }
                    .padding(.top, 18)

                    // stats
                    HStack(spacing: 0) {
                        stat("학습 카드", "\(summary.total)")
                        divider
                        stat("정답", "\(summary.correct)")
                        divider
                        stat("소요 시간", elapsedText)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .cardStyle(soft: true)
                    .padding(.top, 20)

                    // daily review reminder (real local notification)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("복습 알림")
                                .font(.pretendard(12.5, weight: .bold))
                                .foregroundStyle(Theme.primary.opacity(0.85))
                            Text("매일 오후 7시")
                                .font(.pretendard(16, weight: .bold)).kerning(-0.3)
                                .foregroundStyle(Theme.primaryInk).lineLimit(1)
                        }
                        Spacer()
                        Toggle("", isOn: $reminderOn).labelsHidden().tint(Theme.green)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(Theme.lav, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.top, 14)
                    .onChange(of: reminderOn) { _, on in
                        Task { reminderOn = await NotificationService.apply(enabled: on) }
                    }

                    // wrong list
                    if !summary.wrong.isEmpty {
                        HStack {
                            Text("오답 카드").font(.pretendard(16, weight: .bold)).kerning(-0.3)
                            Spacer()
                            Text("\(summary.wrong.count)장").font(.pretendard(13, weight: .bold)).foregroundStyle(Theme.coral)
                        }
                        .padding(.horizontal, 2).padding(.top, 22).padding(.bottom, 12)

                        VStack(spacing: 9) {
                            ForEach(summary.wrong) { card in
                                HStack(spacing: 11) {
                                    Circle().fill(Theme.coral).frame(width: 8, height: 8)
                                    Text(card.front).font(.pretendard(14, weight: .semibold)).kerning(-0.2)
                                        .lineLimit(2)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cardStyle(soft: true)
                            }
                        }
                    }
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 20).padding(.top, 10)
            }

            HStack(spacing: 11) {
                if !summary.wrong.isEmpty {
                    PillButton(title: "오답만 다시", style: .outline) { onRetryWrong(summary.wrong) }
                }
                PillButton(title: "홈으로", style: .primary, action: onHome)
            }
            .dock(soft: true)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(label).font(.pretendard(12, weight: .semibold)).foregroundStyle(Theme.ink2)
            Text(value).font(.pretendard(22, weight: .heavy)).kerning(-0.5).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(Theme.line).frame(width: 1, height: 36)
    }
}

#Preview {
    ResultView(summary: StudySummary(total: 20, correct: 17, elapsedSeconds: 480, wrong: [
        Card(deckId: "d", front: "Optional Chaining의 동작 방식은?", back: "…"),
        Card(deckId: "d", front: "GCD의 main / global queue 차이?", back: "…"),
    ]))
}
