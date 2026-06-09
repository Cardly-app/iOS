//
//  MainTabView.swift
//  Cardly — host for the 4 bottom tabs with the persistent black pill bar.
//

import SwiftUI

struct MainTabView: View {
    var onCreate: () -> Void = {}
    var onReview: () -> Void = {}
    @State private var tab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:  HomeView(onCreate: onCreate, onReview: onReview)
                case .cards: CardsTab(onCreate: onCreate)
                case .chart: ChartTab()
                case .user:  ProfileTab()
                }
            }

            TabBar(selection: $tab)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - Cards tab (all decks)

private struct CardsTab: View {
    @Environment(DeckStore.self) private var deckStore
    var onCreate: () -> Void
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("내 덱").font(.pretendard(34, weight: .heavy)).kerning(-1.1)
                        Spacer()
                        Button(action: onCreate) {
                            Pill(text: "새 덱", systemImage: "plus", fill: Theme.lav, fg: Theme.primary)
                        }.buttonStyle(.plain)
                    }
                    .padding(.bottom, 18)

                    if deckStore.decks.isEmpty {
                        EmptyDecks(onCreate: onCreate).padding(.top, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(deckStore.decks) { DeckRow(d: $0) }
                        }
                        .padding(.bottom, 120)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 4)
            }
        }
    }
}

// MARK: - Chart tab (stats placeholder)

private struct ChartTab: View {
    @Environment(DeckStore.self) private var deckStore
    @State private var stats = Stats(totalCards: 0, avgAccuracy: 0, streakDays: 0,
                                     weekdayCards: Array(repeating: 0, count: 7))

    private let labels = ["월", "화", "수", "목", "금", "토", "일"]
    private var maxCards: Int { max(stats.weekdayCards.max() ?? 0, 1) }
    private var todayIdx: Int { (Calendar.current.component(.weekday, from: Date()) + 5) % 7 }

    var body: some View {
        ZStack {
            Theme.bgSoft.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("통계").font(.pretendard(34, weight: .heavy)).kerning(-1.1)
                        .padding(.bottom, 18)

                    // weekly streak card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("이번 주 학습").font(.pretendard(13.5, weight: .bold))
                                    .foregroundStyle(Theme.ink2)
                                HStack(spacing: 6) {
                                    Text("\(stats.streakDays)일 연속").font(.pretendard(22, weight: .heavy)).kerning(-0.6)
                                    if stats.streakDays > 0 {
                                        Image(systemName: "flame.fill").font(.system(size: 19))
                                            .foregroundStyle(Theme.coral)
                                    }
                                }
                            }
                            Spacer()
                        }
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(Array(labels.enumerated()), id: \.offset) { i, d in
                                let count = stats.weekdayCards[i]
                                let isToday = i == todayIdx
                                VStack(spacing: 6) {
                                    Text(count > 0 ? "\(count)" : " ")
                                        .font(.pretendard(10.5, weight: .bold)).monospacedDigit()
                                        .foregroundStyle(isToday ? Theme.primary : Theme.ink3)
                                        .frame(height: 13)
                                    // bar on a faint rail (so empty days still read as 0, not gaps)
                                    ZStack(alignment: .bottom) {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Theme.line)
                                            .frame(height: 84)
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(count > 0 ? Theme.primary : Color.clear)
                                            .frame(height: count > 0 ? max(14, CGFloat(count) / CGFloat(maxCards) * 84) : 0)
                                    }
                                    .frame(maxWidth: 22)
                                    Text(d).font(.pretendard(11, weight: isToday ? .bold : .semibold))
                                        .foregroundStyle(isToday ? Theme.primary : Theme.ink3)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    HStack(spacing: 12) {
                        miniStat("총 카드", "\(stats.totalCards)", Theme.lav, Theme.lavInk)
                        miniStat("평균 정답률", "\(stats.avgAccuracy)%", Theme.lime, Theme.limeInk)
                    }
                    .padding(.top, 12).padding(.bottom, 120)
                }
                .padding(.horizontal, 20).padding(.top, 4)
            }
        }
        .task { stats = await deckStore.loadStats() }
    }

    private func miniStat(_ l: String, _ v: String, _ fill: Color, _ ink: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(l).font(.pretendard(13, weight: .bold)).foregroundStyle(ink.opacity(0.8))
            Text(v).font(.pretendard(28, weight: .heavy)).kerning(-1).foregroundStyle(ink)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous))
    }
}

// MARK: - Profile tab (placeholder)

private struct ProfileTab: View {
    @Environment(AuthService.self) private var auth

    private var initial: String {
        let name = auth.currentUser?.displayName ?? ""
        return String(name.first.map(String.init) ?? "C").uppercased()
    }

    var body: some View {
        ZStack {
            Theme.bgSoft.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("프로필").font(.pretendard(34, weight: .heavy)).kerning(-1.1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 22)

                    VStack(spacing: 14) {
                        Text(initial).font(.pretendard(34, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 84, height: 84)
                            .background(Theme.primary, in: Circle())
                        Text(auth.currentUser?.displayName ?? "사용자")
                            .font(.pretendard(20, weight: .bold)).kerning(-0.4)
                        Text(auth.currentUser?.email ?? "")
                            .font(.pretendard(14, weight: .medium)).foregroundStyle(Theme.ink2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .cardStyle()

                    VStack(spacing: 0) {
                        row("bell", "복습 알림")
                        Divider().padding(.leading, 56)
                        row("moon", "다크 모드")
                        Divider().padding(.leading, 56)
                        row("questionmark.circle", "도움말")
                    }
                    .cardStyle()
                    .padding(.top, 14)

                    PillButton(title: "로그아웃", style: .outline) { auth.signOut() }
                        .padding(.top, 14).padding(.bottom, 120)
                }
                .padding(.horizontal, 20).padding(.top, 4)
            }
        }
    }

    private func row(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.primary).frame(width: 28)
            Text(title).font(.pretendard(16, weight: .semibold))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.ink3)
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
    }
}

#Preview {
    MainTabView()
        .environment(AuthService.preview)
        .environment(DeckStore.preview)
}
