//
//  ResultView.swift
//  Cardly — Screen 6: Result
//

import SwiftUI

struct ResultView: View {
    var onRetryWrong: () -> Void = {}
    var onHome: () -> Void = {}
    @State private var reminderOn = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bgSoft.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Pill(text: "세션 완료", systemImage: "party.popper.fill", fill: Theme.lime, fg: Theme.limeInk)

                    // donut
                    ZStack {
                        Donut(pct: 85, size: 172)
                        VStack(spacing: 2) {
                            Text("85%").font(.pretendard(44, weight: .heavy)).kerning(-2).monospacedDigit()
                            Text("17 / 20 정답")
                                .font(.pretendard(13.5, weight: .semibold)).foregroundStyle(Theme.ink2)
                                .monospacedDigit()
                        }
                    }
                    .padding(.top, 18)

                    // stats
                    HStack(spacing: 0) {
                        stat("학습 카드", "20")
                        divider
                        stat("정답", "17")
                        divider
                        stat("소요 시간", "8분")
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .cardStyle(soft: true)
                    .padding(.top, 20)

                    // next review
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("다음 복습 알림")
                                .font(.pretendard(12.5, weight: .bold))
                                .foregroundStyle(Theme.primary.opacity(0.85))
                            Text("내일 오후 7시")
                                .font(.pretendard(16, weight: .bold)).kerning(-0.3)
                                .foregroundStyle(Theme.primaryInk).lineLimit(1)
                        }
                        Spacer()
                        Toggle("", isOn: $reminderOn).labelsHidden().tint(Theme.green)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(Theme.lav, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.top, 14)

                    // wrong list
                    HStack {
                        Text("오답 카드").font(.pretendard(16, weight: .bold)).kerning(-0.3)
                        Spacer()
                        Text("3장").font(.pretendard(13, weight: .bold)).foregroundStyle(Theme.coral)
                    }
                    .padding(.horizontal, 2).padding(.top, 22).padding(.bottom, 12)

                    VStack(spacing: 9) {
                        ForEach(SampleData.wrongCards, id: \.self) { w in
                            HStack(spacing: 11) {
                                Circle().fill(Theme.coral).frame(width: 8, height: 8)
                                Text(w).font(.pretendard(14, weight: .semibold)).kerning(-0.2)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle(soft: true)
                        }
                    }
                    .padding(.bottom, 110)
                }
                .padding(.horizontal, 20).padding(.top, 10)
            }

            HStack(spacing: 11) {
                PillButton(title: "오답만 다시", style: .outline, action: onRetryWrong)
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

#Preview { ResultView() }
