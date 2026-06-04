//
//  CreateView.swift
//  Cardly — Screen 3: Deck create
//

import SwiftUI

struct CreateView: View {
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}
    @State private var cardCount: Double = 20   // 10...30

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bgSoft.ignoresSafeArea()

            VStack(spacing: 0) {
                NavBar(title: "새 덱 만들기", backLabel: "뒤로", onBack: onBack)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("어떻게\n만들까요?")
                            .font(.pretendard(27, weight: .heavy)).kerning(-0.8).lineSpacing(2)
                        Text("자료만 주면 AI가 카드로 바꿔드려요.")
                            .font(.pretendard(15, weight: .medium)).foregroundStyle(Theme.ink2)
                            .padding(.top, 8)

                        VStack(spacing: 12) {
                            ForEach(SampleData.createOptions) { OptionRow(o: $0) }
                        }
                        .padding(.top, 22)

                        Rectangle().fill(Theme.line2).frame(height: 1)
                            .padding(.horizontal, 2).padding(.top, 26).padding(.bottom, 18)

                        // card count slider
                        HStack(alignment: .firstTextBaseline) {
                            Text("생성할 카드 수").font(.pretendard(15, weight: .bold)).kerning(-0.3)
                            Spacer()
                            Text("\(Int(cardCount))장")
                                .font(.pretendard(17, weight: .heavy)).foregroundStyle(Theme.primary)
                                .monospacedDigit()
                        }

                        Slider(value: $cardCount, in: 10...30, step: 1)
                            .tint(Theme.primary)
                            .padding(.top, 10)

                        HStack {
                            Text("10"); Spacer(); Text("30")
                        }
                        .font(.pretendard(12, weight: .semibold)).foregroundStyle(Theme.ink3)
                        .monospacedDigit()
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20).padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            PillButton(title: "다음", style: .primary, action: onNext)
                .dock(soft: true)
        }
    }
}

struct OptionRow: View {
    let o: CreateOption
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous).fill(o.tone.fill)
                Image(systemName: o.symbol).font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(o.tone.ink)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(o.title).font(.pretendard(16.5, weight: .bold)).kerning(-0.3)
                    if o.ai {
                        Text("AI").font(.pretendard(10.5, weight: .heavy)).kerning(0.2)
                            .foregroundStyle(Theme.primary)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Theme.lav, in: Capsule())
                    }
                }
                Text(o.subtitle).font(.pretendard(13, weight: .medium)).foregroundStyle(Theme.ink2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.ink3)
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview { CreateView() }
