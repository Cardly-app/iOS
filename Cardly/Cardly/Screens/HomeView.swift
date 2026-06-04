//
//  HomeView.swift
//  Cardly — Screen 2: Home (layout A, list)
//

import SwiftUI

struct HomeView: View {
    var onCreate: () -> Void = {}
    var onReview: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // header
                    HStack {
                        Text("Cardly").font(.pretendard(34, weight: .heavy)).kerning(-1.1)
                        Spacer()
                        Text("K")
                            .font(.pretendard(17, weight: .heavy)).kerning(-0.3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Theme.primary, in: Circle())
                    }

                    // review hero
                    reviewHero
                        .padding(.top, 18)

                    // my decks
                    HStack {
                        Text("내 덱").font(.pretendard(19, weight: .bold)).kerning(-0.4)
                        Spacer()
                        Button(action: onCreate) {
                            Pill(text: "새 덱", systemImage: "plus", fill: Theme.lav, fg: Theme.primary)
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 28).padding(.bottom, 14)

                    VStack(spacing: 12) {
                        ForEach(SampleData.decks) { DeckRow(d: $0) }
                    }
                    .padding(.bottom, 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
    }

    private var reviewHero: some View {
        Button(action: onReview) {
            ZStack(alignment: .topTrailing) {
                HeroDeco()
                VStack(alignment: .leading, spacing: 0) {
                    Text("오늘의 복습")
                        .font(.pretendard(13.5, weight: .bold)).kerning(-0.2)
                        .foregroundStyle(.white.opacity(0.9))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("12").font(.pretendard(56, weight: .heavy)).kerning(-2)
                        Text("장").font(.pretendard(26, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 4)
                    Text("카드가 기다리고 있어요")
                        .font(.pretendard(15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.top, 6)
                    Pill(text: "지금 복습하기", trailingImage: "arrow.right", fill: .white, fg: Theme.primary)
                        .padding(.top, 18)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(EdgeInsets(top: 22, leading: 22, bottom: 24, trailing: 22))
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.rHero, style: .continuous))
            .shadow(color: Theme.primary.opacity(0.30), radius: 34, x: 0, y: 16)
        }
        .buttonStyle(.plain)
    }
}

struct DeckRow: View {
    let d: Deck
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(d.tone.fill)
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(d.tone.ink)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(d.name).font(.pretendard(16, weight: .bold)).kerning(-0.3)
                    .lineLimit(1)
                Text(d.meta).font(.pretendard(13, weight: .medium)).foregroundStyle(Theme.ink2)
                ProgressTrack(pct: d.pct).padding(.top, 6)
            }

            Text("\(Int(d.pct))%")
                .font(.pretendard(16, weight: .heavy)).kerning(-0.5)
                .foregroundStyle(Theme.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .cardStyle()
    }
}

#Preview { HomeView() }
