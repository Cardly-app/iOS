//
//  LoginView.swift
//  Cardly — Screen 1: Login
//

import SwiftUI

struct LoginView: View {
    var onContinue: () -> Void = {}

    var body: some View {
        ZStack {
            // top color / bottom white split
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Theme.primary.frame(height: geo.size.height * 0.52)
                    Color.white
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // hero
                ZStack(alignment: .topLeading) {
                    // soft deco shapes
                    Circle().fill(Color.white.opacity(0.10))
                        .frame(width: 220, height: 220)
                        .offset(x: 200, y: -10)
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(20))
                        .offset(x: 250, y: 150)

                    VStack(alignment: .leading, spacing: 0) {
                        CardsMotif(size: 120, tone: "white")
                        Text("Cardly")
                            .font(.pretendard(52, weight: .heavy)).kerning(-2)
                            .foregroundStyle(.white)
                            .padding(.top, 22)
                        Text("강의자료를 AI 플래시카드로")
                            .font(.pretendard(18, weight: .semibold)).kerning(-0.3)
                            .foregroundStyle(Color.white.opacity(0.86))
                            .padding(.top, 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.top, 44)

                Spacer()

                // actions
                VStack(spacing: 12) {
                    VStack(spacing: 6) {
                        Text("3초 만에 시작하기").font(.pretendard(24, weight: .heavy)).kerning(-0.8)
                        Text("오늘 배운 걸, 내일도 기억하게.")
                            .font(.pretendard(15, weight: .medium)).foregroundStyle(Theme.ink2)
                    }
                    .padding(.bottom, 18)

                    PillButton(title: "Apple로 계속하기", systemImage: "apple.logo", style: .dark, action: onContinue)
                    PillButton(title: "이메일로 시작하기", systemImage: "envelope", style: .outline, action: onContinue)

                    (Text("계속하면 ") + Text("이용약관").underline()
                        + Text("과 ") + Text("개인정보처리방침").underline()
                        + Text("에\n동의하는 것입니다"))
                        .multilineTextAlignment(.center)
                        .font(.pretendard(12.5, weight: .medium))
                        .foregroundStyle(Theme.ink3)
                        .lineSpacing(3)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview { LoginView() }
