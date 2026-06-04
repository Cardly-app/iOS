//
//  StudyView.swift
//  Cardly — Screen 5: Study
//

import SwiftUI

struct StudyView: View {
    var onClose: () -> Void = {}
    var onAnswer: () -> Void = {}

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
                    ProgressTrack(pct: 15, height: 7)
                    Text("3 / 20")
                        .font(.pretendard(13.5, weight: .bold)).foregroundStyle(Theme.ink2)
                        .monospacedDigit().frame(minWidth: 46, alignment: .trailing)
                }
                .padding(.horizontal, 20).padding(.top, 4)

                // card with stacked peek
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white)
                        .frame(height: 40).opacity(0.6)
                        .padding(.horizontal, 34).offset(y: 18)
                        .shadow(color: Color(hex: "#1C1B28").opacity(0.05), radius: 10, y: 2)
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white)
                        .frame(height: 40).opacity(0.8)
                        .padding(.horizontal, 27).offset(y: 24)
                        .shadow(color: Color(hex: "#1C1B28").opacity(0.05), radius: 10, y: 2)

                    cardFace
                }
                .padding(.horizontal, 20).padding(.top, 28)

                Spacer()
            }

            HStack(spacing: 11) {
                PillButton(title: "다시 볼래요", style: .coralOutline, action: onAnswer)
                PillButton(title: "외웠어요", style: .green, action: onAnswer)
            }
            .dock(soft: true)
        }
    }

    private var cardFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("질문", color: Theme.ink2)
            Text("SwiftUI에서 @State와 @Binding의 차이는 무엇인가?")
                .font(.pretendard(23, weight: .bold)).kerning(-0.5).lineSpacing(5)
                .padding(.top, 8)

            Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 20)

            eyebrow("정답", color: Theme.primary)
            Text("@State는 뷰가 직접 소유하는 상태이고, @Binding은 부모 뷰로부터 전달받은 상태에 대한 양방향 참조입니다.")
                .font(.pretendard(16, weight: .medium)).lineSpacing(6)
                .padding(.top, 8)

            HStack(spacing: 7) {
                Image(systemName: "sparkles").font(.system(size: 14))
                Text("AI 설명 보기").font(.pretendard(13.5, weight: .semibold))
            }
            .foregroundStyle(Theme.primary)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .overlay(Capsule().stroke(Theme.line2, lineWidth: 1.5))
            .padding(.top, 18)
        }
        .padding(EdgeInsets(top: 26, leading: 22, bottom: 24, trailing: 22))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "#28265A").opacity(0.18), radius: 40, x: 0, y: 14)
    }

    private func eyebrow(_ t: String, color: Color) -> some View {
        Text(t).font(.pretendard(12, weight: .bold)).kerning(0.4)
            .textCase(.uppercase).foregroundStyle(color)
    }
}

#Preview { StudyView() }
