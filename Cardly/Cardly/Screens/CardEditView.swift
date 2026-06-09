//
//  CardEditView.swift
//  Cardly — edit a card's question/answer (presented as a sheet)
//

import SwiftUI

struct CardEditView: View {
    let card: Card
    var onSave: @MainActor (_ front: String, _ back: String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var front: String
    @State private var back: String
    @State private var saving = false

    init(card: Card, onSave: @escaping @MainActor (_ front: String, _ back: String) async -> Void) {
        self.card = card
        self.onSave = onSave
        _front = State(initialValue: card.front)
        _back = State(initialValue: card.back)
    }

    private var canSave: Bool {
        !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // top bar
            ZStack {
                Text("카드 편집").font(.pretendard(17, weight: .bold)).kerning(-0.3)
                HStack {
                    Button("취소") { dismiss() }
                        .font(.pretendard(16, weight: .semibold)).foregroundStyle(Theme.ink2)
                    Spacer()
                    Button("저장") {
                        Task { @MainActor in
                            saving = true
                            await onSave(front.trimmingCharacters(in: .whitespacesAndNewlines),
                                         back.trimmingCharacters(in: .whitespacesAndNewlines))
                            saving = false
                            dismiss()
                        }
                    }
                    .font(.pretendard(16, weight: .bold))
                    .foregroundStyle(canSave ? Theme.primary : Theme.ink3)
                    .disabled(!canSave || saving)
                }
            }
            .frame(height: 52)
            .padding(.horizontal, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    field(label: "질문", text: $front, minHeight: 80)
                    field(label: "정답", text: $back, minHeight: 120)
                }
                .padding(20)
            }
        }
        .background(Theme.bgSoft)
        .presentationDragIndicator(.visible)
    }

    private func field(label: String, text: Binding<String>, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.pretendard(12, weight: .bold)).kerning(0.4)
                .textCase(.uppercase).foregroundStyle(Theme.ink2)
            TextEditor(text: text)
                .font(.pretendard(15, weight: .medium))
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    CardEditView(card: Card(deckId: "d", front: "SwiftUI에서 @State와 @Binding의 차이는?",
                            back: "@State는 뷰가 소유, @Binding은 부모로부터의 양방향 참조.")) { _, _ in }
}
