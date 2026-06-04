//
//  Theme.swift
//  Cardly
//
//  Design system — ported from the Cardly hi-fi design (light, soft-vivid).
//

import SwiftUI

// MARK: - Color tokens

extension Color {
    init(hex: String) {
        let s = Scanner(string: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        var v: UInt64 = 0
        s.scanHexInt64(&v)
        let r, g, b, a: Double
        if hex.count > 7 { // includes alpha
            r = Double((v & 0xFF000000) >> 24) / 255
            g = Double((v & 0x00FF0000) >> 16) / 255
            b = Double((v & 0x0000FF00) >> 8) / 255
            a = Double(v & 0x000000FF) / 255
        } else {
            r = Double((v & 0xFF0000) >> 16) / 255
            g = Double((v & 0x00FF00) >> 8) / 255
            b = Double(v & 0x0000FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

enum Theme {
    // surfaces
    static let bg        = Color(hex: "#FFFFFF")
    static let bgSoft    = Color(hex: "#F6F6F9")
    static let ink       = Color(hex: "#16151C")
    static let ink2      = Color(hex: "#908FA0")
    static let ink3      = Color(hex: "#B7B6C4")
    static let line      = Color(hex: "#ECEBF2")
    static let line2     = Color(hex: "#E2E1EB")

    // brand — desaturated periwinkle
    static let primary     = Color(hex: "#5E5CE6")
    static let primaryDeep = Color(hex: "#3F3DBF")
    static let primaryInk  = Color(hex: "#322F8F")

    // soft-vivid card palette
    static let lav      = Color(hex: "#E7E5FB"); static let lavInk   = Color(hex: "#3D3A9E")
    static let sky      = Color(hex: "#C2DAF2"); static let skyInk   = Color(hex: "#235184")
    static let lime     = Color(hex: "#D4E58A"); static let limeInk  = Color(hex: "#4E6313")
    static let peach    = Color(hex: "#F4C58A"); static let peachInk = Color(hex: "#8A5414")
    static let pink     = Color(hex: "#F3C5DD"); static let pinkInk  = Color(hex: "#9B3F73")

    // semantic
    static let green     = Color(hex: "#3FB178"); static let greenSoft = Color(hex: "#E3F4EC")
    static let coral     = Color(hex: "#E96A5C"); static let coralSoft = Color(hex: "#FCEAE7")

    // radii
    static let rHero: CGFloat = 26
    static let rCard: CGFloat = 20
    static let rTile: CGFloat = 16
    static let rPill: CGFloat = 999
}

// Named palette tone used by deck rows / create options
enum Tone: String {
    case lav, sky, lime, peach, pink
    var fill: Color {
        switch self {
        case .lav: return Theme.lav
        case .sky: return Theme.sky
        case .lime: return Theme.lime
        case .peach: return Theme.peach
        case .pink: return Theme.pink
        }
    }
    var ink: Color {
        switch self {
        case .lav: return Theme.lavInk
        case .sky: return Theme.skyInk
        case .lime: return Theme.limeInk
        case .peach: return Theme.peachInk
        case .pink: return Theme.pinkInk
        }
    }
}

// MARK: - Typography
// Uses Pretendard if the font is installed in the bundle; otherwise falls back
// to the system font (SF Pro / Apple SD Gothic Neo), which is the native iOS choice.

extension Font {
    static func pretendard(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "Pretendard-Bold"
        case .semibold: name = "Pretendard-SemiBold"
        case .medium: name = "Pretendard-Medium"
        default: name = "Pretendard-Regular"
        }
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }
}

// MARK: - Reusable view modifiers

struct CardStyle: ViewModifier {
    var radius: CGFloat = Theme.rCard
    var soft: Bool = false
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color(hex: "#1C1B28").opacity(soft ? 0.05 : 0.06),
                    radius: soft ? 10 : 22, x: 0, y: soft ? 2 : 6)
    }
}

extension View {
    func cardStyle(radius: CGFloat = Theme.rCard, soft: Bool = false) -> some View {
        modifier(CardStyle(radius: radius, soft: soft))
    }
}
