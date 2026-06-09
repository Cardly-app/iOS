//
//  GeneratingOverlay.swift
//  Cardly
//
//  Full-screen step loader shown over CreateView while we read a PDF and
//  generate cards. Replaces the scattered inline spinners with one calm,
//  sequential progress view.
//

import SwiftUI

/// Where the create flow is in the read → generate pipeline.
enum GenPhase: Equatable {
    case reading        // PDF text extraction / OCR (PDF source only)
    case generating     // AI card generation
    case failed(String) // something went wrong; show message + retry/back
}

struct GeneratingOverlay: View {
    let phase: GenPhase
    let isPDF: Bool
    var onRetry: () -> Void = {}
    var onBack: () -> Void = {}

    /// Ordered steps for the current source. PDF reads first; others go straight to AI.
    private var steps: [(phase: GenPhase, title: String, sub: String)] {
        var s: [(GenPhase, String, String)] = []
        if isPDF {
            s.append((.reading, "PDF 읽는 중", "텍스트 추출·OCR 진행 중이에요"))
        }
        s.append((.generating, "AI가 카드 만드는 중", "핵심을 골라 카드로 정리하고 있어요"))
        return s
    }

    /// Index of the active step (reading=0 when PDF, generating next). -1 when failed.
    private var activeIndex: Int {
        switch phase {
        case .reading:    return 0
        case .generating: return isPDF ? 1 : 0
        case .failed:     return -1
        }
    }

    var body: some View {
        ZStack {
            Theme.bgSoft.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                CardsMotif(size: 120, tone: "lav")

                if case .failed(let message) = phase {
                    Text("문제가 생겼어요")
                        .font(.pretendard(22, weight: .heavy)).kerning(-0.5)
                        .padding(.top, 30)
                    Text(message)
                        .font(.pretendard(15, weight: .medium)).foregroundStyle(Theme.ink2)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10).padding(.horizontal, 36)
                } else {
                    Text("카드를 만들고 있어요")
                        .font(.pretendard(22, weight: .heavy)).kerning(-0.5)
                        .padding(.top, 30)
                    Text("잠깐이면 끝나요. 화면을 닫지 말아주세요.")
                        .font(.pretendard(15, weight: .medium)).foregroundStyle(Theme.ink2)
                        .padding(.top, 10)

                    VStack(spacing: 14) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                            stepRow(title: step.title, sub: step.sub, index: i)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                    .padding(.horizontal, 24).padding(.top, 30)
                }

                Spacer()

                if case .failed = phase {
                    VStack(spacing: 10) {
                        PillButton(title: "다시 시도", style: .primary, action: onRetry)
                        PillButton(title: "뒤로", style: .outline, action: onBack)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 24)
                }
            }
        }
    }

    @ViewBuilder
    private func stepRow(title: String, sub: String, index: Int) -> some View {
        let done = index < activeIndex
        let active = index == activeIndex

        HStack(spacing: 14) {
            ZStack {
                if active {
                    ProgressView().tint(Theme.primary)
                } else if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22)).foregroundStyle(Theme.primary)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22)).foregroundStyle(Theme.ink3)
                }
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pretendard(15.5, weight: .bold)).kerning(-0.3)
                    .foregroundStyle(active || done ? Theme.ink : Theme.ink3)
                if active {
                    Text(sub)
                        .font(.pretendard(13, weight: .medium)).foregroundStyle(Theme.ink2)
                }
            }
            Spacer(minLength: 0)
        }
        .opacity(active || done ? 1 : 0.6)
    }
}

#Preview {
    GeneratingOverlay(phase: .reading, isPDF: true)
}
