//
//  PreviewView.swift
//  Cardly — Screen 4: Preview generated cards
//

import SwiftUI

struct PreviewView: View {
    var onBack: () -> Void = {}
    var onSave: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bgSoft.ignoresSafeArea()

            VStack(spacing: 0) {
                NavBar(title: "미리보기", onBack: onBack) {
                    Button(action: onSave) {
                        Text("저장").font(.pretendard(16, weight: .bold)).foregroundStyle(Theme.primary)
                    }.buttonStyle(.plain)
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // success banner
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Theme.primary, in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("카드 20장이 생성됐어요")
                                    .font(.pretendard(15.5, weight: .bold)).kerning(-0.3)
                                    .foregroundStyle(Theme.primaryInk).lineLimit(1)
                                Text("확인하고 필요하면 편집하세요")
                                    .font(.pretendard(13, weight: .medium))
                                    .foregroundStyle(Theme.primaryInk.opacity(0.7)).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(Theme.lav, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        // title field
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("덱 이름")
                                    .font(.pretendard(11, weight: .bold)).kerning(0.4)
                                    .textCase(.uppercase).foregroundStyle(Theme.ink2)
                                Text("iOS 프로그래밍 기말")
                                    .font(.pretendard(17, weight: .bold)).kerning(-0.3).lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "pencil").font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.ink3)
                        }
                        .padding(.horizontal, 18).padding(.vertical, 16)
                        .cardStyle(soft: true)
                        .padding(.top, 16)

                        HStack {
                            Text("생성된 카드").font(.pretendard(15, weight: .bold)).kerning(-0.3)
                            Spacer()
                            Text("20장").font(.pretendard(13, weight: .semibold)).foregroundStyle(Theme.ink2)
                        }
                        .padding(.horizontal, 2).padding(.top, 22).padding(.bottom, 12)

                        VStack(spacing: 12) {
                            ForEach(SampleData.previewCards) { PreviewCard(c: $0) }
                        }
                        .padding(.bottom, 110)
                    }
                    .padding(.horizontal, 20).padding(.top, 6)
                }
            }

            PillButton(title: "카드 직접 추가", systemImage: "plus", style: .outline, action: onSave)
                .dock(soft: true)
        }
    }
}

struct PreviewCard: View {
    let c: Flashcard
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 9) {
                qaBadge("Q", fg: Theme.primary, bg: Theme.lav)
                Text(c.q).font(.pretendard(15, weight: .bold)).kerning(-0.3).lineSpacing(2)
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    Image(systemName: "pencil"); Image(systemName: "trash")
                }
                .font(.system(size: 15, weight: .regular)).foregroundStyle(Theme.ink3)
            }
            HStack(alignment: .top, spacing: 9) {
                qaBadge("A", fg: Theme.ink2, bg: Theme.bgSoft)
                Text(c.a).font(.pretendard(14, weight: .medium)).foregroundStyle(Theme.ink2).lineSpacing(2)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func qaBadge(_ t: String, fg: Color, bg: Color) -> some View {
        Text(t).font(.pretendard(11, weight: .heavy)).foregroundStyle(fg)
            .frame(width: 20, height: 20)
            .background(bg, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview { PreviewView() }
