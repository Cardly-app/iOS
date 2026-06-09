//
//  CreateView.swift
//  Cardly — Screen 3: Deck create (pick source → input → generate)
//

import SwiftUI
import UniformTypeIdentifiers

struct CreateView: View {
    var onBack: () -> Void = {}
    var onGenerated: (DraftDeck) -> Void = { _ in }

    @State private var selected = 0          // index into SampleData.createOptions
    @State private var content = ""
    @State private var cardCount: Double = 20   // 10...30
    @State private var generating = false
    @State private var phase: GenPhase = .generating   // step shown in the loading overlay
    @State private var pdfFileName: String?
    @State private var pdfURL: URL?          // picked PDF; extracted lazily on "다음"
    @State private var showImporter = false
    @FocusState private var contentFocused: Bool

    private let ai: AIService = AppAI.make()

    private var sourceType: SourceType { [SourceType.text, .pdf, .prompt][selected] }

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
                            ForEach(Array(SampleData.createOptions.enumerated()), id: \.offset) { i, o in
                                Button { selectSource(i) } label: {
                                    OptionRow(o: o, selected: selected == i)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 22)

                        // source content input
                        inputArea
                            .padding(.top, 18)

                        Rectangle().fill(Theme.line2).frame(height: 1)
                            .padding(.horizontal, 2).padding(.top, 22).padding(.bottom, 18)

                        // card count slider
                        HStack(alignment: .firstTextBaseline) {
                            Text("생성할 카드 수").font(.pretendard(15, weight: .bold)).kerning(-0.3)
                            Spacer()
                            Text("\(Int(cardCount))장")
                                .font(.pretendard(17, weight: .heavy)).foregroundStyle(Theme.primary)
                                .monospacedDigit()
                        }
                        Slider(value: $cardCount, in: 10...30, step: 1)
                            .tint(Theme.primary).padding(.top, 10)
                        HStack { Text("10"); Spacer(); Text("30") }
                            .font(.pretendard(12, weight: .semibold)).foregroundStyle(Theme.ink3)
                            .monospacedDigit().padding(.top, 4)
                    }
                    .padding(.horizontal, 20).padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            PillButton(title: "다음",
                       style: canGenerate ? .primary : .disabled) {
                contentFocused = false
                Task { await generate() }
            }
            .disabled(!canGenerate || generating)
            .dock(soft: true)

            if generating {
                GeneratingOverlay(
                    phase: phase,
                    isPDF: sourceType == .pdf,
                    onRetry: { Task { await generate() } },
                    onBack: { generating = false }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: generating)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf]) { result in
            guard case .success(let url) = result else { return }
            content = ""
            pdfURL = url
            pdfFileName = url.lastPathComponent
        }
    }

    private func selectSource(_ i: Int) {
        withAnimation(.easeOut(duration: 0.15)) { selected = i }
        content = ""
        pdfFileName = nil
        pdfURL = nil
        contentFocused = false
        // PDF needs a file, not typed input — open the picker right away.
        if [SourceType.text, .pdf, .prompt][i] == .pdf { showImporter = true }
    }

    @ViewBuilder
    private var inputArea: some View {
        switch sourceType {
        case .pdf:
            if let name = pdfFileName {
                // Selected file — a compact attachment chip, not an option-style card.
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16)).foregroundStyle(Theme.skyInk)
                    Text(name)
                        .font(.pretendard(14.5, weight: .semibold)).lineLimit(1)
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 8)
                    Button { showImporter = true } label: {
                        Text("변경").font(.pretendard(13.5, weight: .bold))
                            .foregroundStyle(Theme.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Theme.sky.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                // No file yet — a slim dashed control (the picker also auto-opens on select).
                Button { showImporter = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus").font(.system(size: 16, weight: .semibold))
                        Text("PDF 파일 선택").font(.pretendard(14.5, weight: .bold))
                    }
                    .foregroundStyle(Theme.skyInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Theme.sky, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }
                .buttonStyle(.plain)
            }
        default:
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text(sourceType == .prompt ? "주제를 입력하세요 (예: iOS 메모리 관리)"
                                                   : "강의노트나 정리 자료를 붙여넣으세요")
                            .font(.pretendard(15, weight: .medium)).foregroundStyle(Theme.ink3)
                            .padding(.top, 4).padding(.leading, 4)
                    }
                    TextEditor(text: $content)
                        .font(.pretendard(15, weight: .medium))
                        .focused($contentFocused)
                        .frame(minHeight: sourceType == .prompt ? 44 : 120)
                        .scrollContentBackground(.hidden)
                }
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(soft: true)
        }
    }

    private var canGenerate: Bool {
        if sourceType == .pdf { return pdfURL != nil }
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func generate() async {
        generating = true

        // PDF: read text inside the loading screen before generating.
        if sourceType == .pdf {
            guard let url = pdfURL else { generating = false; return }
            phase = .reading
            let text = await PDFTextExtractor.extract(from: url)
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                phase = .failed("이 PDF에서 텍스트를 찾지 못했어요.\n스캔 품질이 낮거나 빈 문서일 수 있어요.")
                return
            }
            content = text
        }

        phase = .generating
        let input = AIInput(sourceType: sourceType, content: content)
        do {
            let drafts = try await ai.generateCards(from: input, count: Int(cardCount))
            guard !drafts.isEmpty else {
                phase = .failed("카드를 만들지 못했어요.\n자료를 더 구체적으로 입력해보세요.")
                return
            }
            onGenerated(DraftDeck(title: defaultTitle, sourceType: sourceType, drafts: drafts))
            generating = false   // Preview is pushed on top; clear so a back-nav has no stale overlay
        } catch {
            phase = .failed("생성에 실패했어요.\n네트워크를 확인하고 다시 시도해주세요.")
        }
    }

    private var defaultTitle: String {
        if sourceType == .pdf, let name = pdfFileName {
            let base = name.hasSuffix(".pdf") ? String(name.dropLast(4)) : name
            if !base.isEmpty { return String(base.prefix(30)) }
        }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if sourceType == .prompt, !trimmed.isEmpty { return trimmed }
        if let firstLine = trimmed.split(separator: "\n").first, !firstLine.isEmpty {
            return String(firstLine.prefix(30))
        }
        return "새 덱"
    }
}

struct OptionRow: View {
    let o: CreateOption
    var selected: Bool = false
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
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(selected ? Theme.primary : Theme.ink3)
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous)
                .stroke(selected ? Theme.primary : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color(hex: "#1C1B28").opacity(0.06), radius: 22, x: 0, y: 6)
    }
}

#Preview { CreateView() }
