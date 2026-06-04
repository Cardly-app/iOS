//
//  Components.swift
//  Cardly
//
//  Shared UI: pill buttons, chips, progress, tab bar, and the abstract graphics.
//

import SwiftUI

// MARK: - Buttons

enum PillStyle {
    case primary, dark, outline, green, coralOutline, disabled
}

struct PillButton: View {
    var title: String
    var systemImage: String? = nil
    var style: PillStyle = .primary
    var small: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: small ? 15 : 17, weight: .semibold))
                }
                Text(title)
                    .font(.pretendard(small ? 15 : 16.5, weight: .bold))
                    .kerning(-0.3)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: small ? 48 : 56)
            .foregroundStyle(fg)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rPill, style: .continuous)
                    .stroke(border, lineWidth: hasBorder ? 1.5 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.rPill, style: .continuous))
            .shadow(color: shadow, radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var fg: Color {
        switch style {
        case .primary, .dark, .green: return .white
        case .outline: return Theme.ink
        case .coralOutline: return Theme.coral
        case .disabled: return Theme.ink3
        }
    }
    private var bg: Color {
        switch style {
        case .primary: return Theme.primary
        case .dark: return Theme.ink
        case .green: return Theme.green
        case .outline, .coralOutline: return .white
        case .disabled: return Theme.bgSoft
        }
    }
    private var border: Color {
        switch style {
        case .outline: return Theme.line2
        case .coralOutline: return Theme.coral
        default: return .clear
        }
    }
    private var hasBorder: Bool { style == .outline || style == .coralOutline }
    private var shadow: Color {
        switch style {
        case .primary: return Theme.primary.opacity(0.28)
        case .green: return Theme.green.opacity(0.28)
        default: return .clear
        }
    }
}

// MARK: - Pill / Chip

struct Pill: View {
    var text: String
    var systemImage: String? = nil
    var trailingImage: String? = nil
    var fill: Color = Theme.bgSoft
    var fg: Color = Theme.ink2
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 14, weight: .bold)) }
            Text(text).font(.pretendard(14, weight: .bold)).kerning(-0.2).lineLimit(1)
            if let trailingImage { Image(systemName: trailingImage).font(.system(size: 14, weight: .bold)) }
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .foregroundStyle(fg)
        .background(fill, in: Capsule())
    }
}

// MARK: - Progress track

struct ProgressTrack: View {
    var pct: Double           // 0...100
    var height: CGFloat = 6
    var fill: Color = Theme.primary
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                Capsule().fill(fill).frame(width: geo.size.width * pct / 100)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Bottom tab bar (black pill)

enum AppTab: String, CaseIterable {
    case home, cards, chart, user
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .cards: return "rectangle.on.rectangle.fill"
        case .chart: return "chart.bar.fill"
        case .user: return "person.fill"
        }
    }
}

struct TabBar: View {
    @Binding var selection: AppTab
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let on = tab == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selection = tab }
                } label: {
                    ZStack {
                        if on { Circle().fill(.white) }
                        Image(systemName: tab.symbol)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(on ? Theme.ink : Color.white.opacity(0.55))
                    }
                    .frame(width: 48, height: 48)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 66)
        .background(Theme.ink, in: Capsule())
        .shadow(color: Theme.ink.opacity(0.28), radius: 30, x: 0, y: 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Abstract graphics

/// Stacked flashcards motif — used in login / hero.
struct CardsMotif: View {
    var size: CGFloat = 132
    var tone: String = "white"   // "white" on color, else periwinkle

    private var a: Color { tone == "white" ? Color.white.opacity(0.95) : Theme.primary }
    private var b: Color { tone == "white" ? Color.white.opacity(0.5)  : Theme.primary.opacity(0.4) }
    private var c: Color { tone == "white" ? Color.white.opacity(0.28) : Theme.primary.opacity(0.18) }
    private var lineOp: Double { tone == "white" ? 0.9 : 0.35 }
    private var lineOp2: Double { tone == "white" ? 0.5 : 0.2 }

    var body: some View {
        let s = size / 132
        ZStack {
            card(c).rotationEffect(.degrees(-13)).offset(x: -3 * s, y: 5 * s)
            card(b).rotationEffect(.degrees(-5)).offset(x: 0, y: 0)
            ZStack(alignment: .topLeading) {
                card(a)
                VStack(alignment: .leading, spacing: 6 * s) {
                    Capsule().fill(Theme.primary.opacity(lineOp)).frame(width: 40 * s, height: 6 * s)
                    Capsule().fill(Theme.primary.opacity(lineOp2)).frame(width: 54 * s, height: 5 * s)
                    Capsule().fill(Theme.primary.opacity(lineOp2)).frame(width: 30 * s, height: 5 * s)
                }
                .padding(.leading, 12 * s).padding(.top, 14 * s)
            }
        }
        .frame(width: size, height: size)
    }

    private func card(_ fill: Color) -> some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(fill)
            .frame(width: 78 * (size / 132), height: 60 * (size / 132))
    }
}

/// Loose geometric confetti for the hero card (decorative).
struct HeroDeco: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.16)).frame(width: 60, height: 60).offset(x: 35, y: -41)
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(0.12)).frame(width: 40, height: 40)
                .rotationEffect(.degrees(18)).offset(x: 23, y: 15)
            Circle().fill(Theme.lime).frame(width: 18, height: 18).offset(x: 51, y: 21)
            Image(systemName: "sparkle")
                .font(.system(size: 26)).foregroundStyle(Color.white.opacity(0.22))
                .offset(x: -35, y: -51)
        }
        .frame(width: 150, height: 150)
        .offset(x: 75, y: -10)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// Donut progress ring for the result screen.
struct Donut: View {
    var pct: Double = 85
    var size: CGFloat = 168
    var body: some View {
        ZStack {
            Circle().stroke(Theme.line, lineWidth: 15)
            Circle()
                .trim(from: 0, to: pct / 100)
                .stroke(Theme.primary, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom nav bar (back / title / trailing)

struct NavBar<Trailing: View>: View {
    var title: String
    var showBack: Bool = true
    var backLabel: String? = nil
    var onBack: () -> Void = {}
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ZStack {
            Text(title).font(.pretendard(17, weight: .bold)).kerning(-0.3)
            HStack {
                if showBack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                            if let backLabel { Text(backLabel).font(.pretendard(16, weight: .semibold)) }
                        }
                        .foregroundStyle(Theme.primary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                trailing()
            }
        }
        .frame(height: 52)
        .padding(.horizontal, 18)
    }
}

extension NavBar where Trailing == EmptyView {
    init(title: String, showBack: Bool = true, backLabel: String? = nil, onBack: @escaping () -> Void = {}) {
        self.init(title: title, showBack: showBack, backLabel: backLabel, onBack: onBack) { EmptyView() }
    }
}

// MARK: - Sticky bottom dock gradient background

struct DockBackground: ViewModifier {
    var soft: Bool = false
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(
                LinearGradient(
                    colors: [(soft ? Theme.bgSoft : .white).opacity(0), soft ? Theme.bgSoft : .white],
                    startPoint: .top, endPoint: .center
                )
            )
    }
}

extension View {
    func dock(soft: Bool = false) -> some View { modifier(DockBackground(soft: soft)) }
}
