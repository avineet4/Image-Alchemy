import SwiftUI

// MARK: - Preference keys for instant-drag hit-testing (drop onto blanks)

private struct WordChipFramesPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] { [:] }
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, n in n }
    }
}

private struct BlankFramesPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] { [:] }
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, n in n }
    }
}

struct FillInTheBlanksView: View {
    @Bindable var viewModel: FillInTheBlanksViewModel
    @State private var resultAppearCount = 0
    @State private var draggingWord: String?
    @State private var dragOffset: CGSize = .zero
    @State private var wordChipFrames: [String: CGRect] = [:]
    @State private var blankFrames: [Int: CGRect] = [:]

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isGenerating && viewModel.questions.isEmpty {
                FillInTheBlanksGeneratingView(generationSteps: viewModel.generationSteps)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.questions.isEmpty {
                FillInTheBlanksEmptyStateView(
                    isGenerating: viewModel.isGenerating,
                    error: viewModel.generationError
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                KnowledgeProgressIndicator(
                    currentIndex: viewModel.currentIndex,
                    totalCount: viewModel.questions.count,
                    labelFormat: { "Question \($0) of \($1)" },
                    activeColor: knowledgeAccentColor,
                    dotColor: { viewModel.dotColor(for: $0) }
                )
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        if let question = viewModel.currentQuestion {
                            sentenceSection(question)
                            if !viewModel.hasChecked && viewModel.allBlanksFilled {
                                checkAnswerButton
                                    .frame(maxWidth: .infinity)
                            }
                            if viewModel.hasChecked {
                                let correct = viewModel.correctCount(for: question)
                                HStack(spacing: 12) {
                                    resultSection(total: question.answers.count, correct: correct)
                                    if correct != question.answers.count {
                                        Button {
                                            viewModel.resetCurrentQuestion()
                                        } label: {
                                            Label("Try again", systemImage: "arrow.counterclockwise")
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 18)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .background(Capsule().fill(knowledgeAccentColor.opacity(0.70)))
                                        .glassEffect(.regular, in: .capsule)
                                        .overlay(Capsule().stroke(knowledgeAccentColor.opacity(0.6), lineWidth: 1))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            if let error = viewModel.generationError {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(24)
                }
                
                wordBankSection
                
                StepNavigationButtons(
                    canGoPrevious: viewModel.canGoPrevious,
                    canGoNext: viewModel.canGoNext,
                    onPrevious: { viewModel.goToPrevious() },
                    onNext: { viewModel.goToNext() }
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .onPreferenceChange(WordChipFramesPreferenceKey.self) { wordChipFrames = $0 }
        .onPreferenceChange(BlankFramesPreferenceKey.self) { blankFrames = $0 }
        .overlay { instantDragOverlay }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Fill in the Blanks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Show reset only when we have questions and we're not generating
                if !viewModel.isGenerating && !viewModel.questions.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                            viewModel.questions = []
                            viewModel.wordBank = []
                            viewModel.userFills = [:]
                            viewModel.userFillsByQuestion = [:]
                            viewModel.checkedQuestionResults = [:]
                            viewModel.currentIndex = 0
                            viewModel.generationSteps = []
                            viewModel.generationError = nil
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                
                Button {
                    Task {
                        await viewModel.generateFillInBlanksWithAI(forceRefresh: true)
                    }
                } label: {
                    if viewModel.isGenerating {
                        ProgressView()
                    } else {
                        Text("Generate with AI")
                            .fontWeight(.semibold)
                    }
                }
                .tint(knowledgeAccentColor)
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isGenerating)
            }
        }
    }
    
    private func sentenceSection(_ question: FillInBlankQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fill in the blanks by dragging words from below:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 6) {
                ForEach(Array(question.segments.enumerated()), id: \.offset) { _, segment in
                    switch segment {
                    case .text(let text):
                        Text(text)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                    case .blank(let index):
                        BlankSlotView(
                            filledWord: viewModel.userFills[index],
                            correctWord: question.answers[index],
                            hasChecked: viewModel.hasChecked,
                            onDrop: { viewModel.placeWord($0, inBlank: index) },
                            onRemove: { viewModel.removeFromBlank(index) }
                        )
                        .background(
                            GeometryReader { g in
                                Color.clear.preference(key: BlankFramesPreferenceKey.self, value: [index: g.frame(in: .global)])
                            }
                        )
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    private var checkAnswerButton: some View {
        Button {
            viewModel.checkAnswer()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body.weight(.semibold))
                Text("Check Answer")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .glassEffect(.regular.tint(knowledgeAccentColor.opacity(0.70)).interactive(), in: .capsule)
        .foregroundStyle(.white)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func resultSection(total: Int, correct: Int) -> some View {
        let totalCount = max(total, 1)
        let score = Double(correct) / Double(totalCount)
        let allCorrect = correct == totalCount
        let allWrong = correct == 0
        let blendWidth = 0.45
        let resultGradient = LinearGradient(
            stops: [
                .init(color: Color.green.opacity(0.38), location: 0),
                .init(color: Color.green.opacity(0.38), location: max(0, score - blendWidth / 2)),
                .init(color: Color.red.opacity(0.38), location: min(1, score + blendWidth / 2)),
                .init(color: Color.red.opacity(0.38), location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        return HStack(spacing: 10) {
            Image(systemName: allCorrect ? "checkmark.circle.fill" : (allWrong ? "xmark.circle.fill" : "exclamationmark.circle.fill"))
                .font(.title3)
                .foregroundStyle(.white)
                .symbolEffect(.bounce, value: resultAppearCount)
                .frame(width: 32, height: 32)
                .background(Circle().fill(allCorrect ? Color.green : (allWrong ? Color.red : Color(.systemGray3))))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(correct) of \(totalCount) correct")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(allCorrect || allWrong ? .white : .primary)
                Text(allCorrect ? "Perfect!" : (allWrong ? "Try again" : "Keep practicing!"))
                    .font(.caption2)
                    .foregroundStyle(allCorrect || allWrong ? .white.opacity(0.9) : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            Group {
                if allCorrect {
                    Capsule().fill(Color.green.opacity(0.55))
                } else if allWrong {
                    Capsule().fill(Color.red.opacity(0.55))
                } else {
                    Capsule().fill(resultGradient)
                }
            }
        )
        .glassEffect(.regular, in: .capsule)
        .overlay(
            Capsule()
                .stroke(allCorrect ? Color.green.opacity(0.6) : (allWrong ? Color.red.opacity(0.6) : Color.primary.opacity(0.12)), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal: .opacity
        ))
        .onAppear {
            resultAppearCount += 1
        }
    }
    
    @ViewBuilder
    private var instantDragOverlay: some View {
        if let word = draggingWord, let frame = wordChipFrames[word] {
            GeometryReader { geo in
                let overlayGlobal = geo.frame(in: .global)
                let x = frame.midX + dragOffset.width - overlayGlobal.minX
                let y = frame.midY + dragOffset.height - overlayGlobal.minY
                WordChipView(word: word)
                    .position(x: x, y: y)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
    }

    private var wordBankSection: some View {
        VStack(spacing: 12) {
            Text("Word Bank")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FlowLayout(spacing: 10) {
                ForEach(viewModel.wordBank, id: \.self) { word in
                    WordChipView(word: word)
                        .opacity(draggingWord == word ? 0.4 : 1)
                        .background(
                            GeometryReader { g in
                                Color.clear.preference(key: WordChipFramesPreferenceKey.self, value: [word: g.frame(in: .global)])
                            }
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if draggingWord == nil { draggingWord = word }
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    defer { draggingWord = nil; dragOffset = .zero }
                                    guard let frame = wordChipFrames[word] else { return }
                                    let dropPoint = CGPoint(x: frame.midX + value.translation.width, y: frame.midY + value.translation.height)
                                    if let (blankIndex, _) = blankFrames.first(where: { $0.value.contains(dropPoint) }) {
                                        viewModel.placeWord(word, inBlank: blankIndex)
                                    }
                                }
                        )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .padding(24)
        .background(Color(.systemGroupedBackground))
    }
}

private struct FillInTheBlanksEmptyStateView: View {
    let isGenerating: Bool
    let error: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.insert")
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .foregroundStyle(knowledgeAccentColor)
                .symbolEffect(.pulse.byLayer, options: .repeating)
            
            VStack(spacing: 4) {
                Text(isGenerating ? "Generating questions…" : "No fill-in-the-blank questions yet")
                    .font(.title.weight(.semibold))
                
                Text(isGenerating
                     ? "Creating sentences with blanks from your Image Alchemy walkthrough."
                     : "Generate fill-in-the-blank questions with Apple Intelligence to test your diffusion knowledge.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Label("Based on your Image Alchemy walkthrough", systemImage: "sparkles")
                Label("Drag words into blanks", systemImage: "hand.draw")
                Label("Instant feedback when you check", systemImage: "checkmark.circle")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 420, alignment: .leading)
            
            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

private struct FillInTheBlanksGeneratingView: View {
    let generationSteps: [GenerationStep]
    @State private var show = false
    @State private var showSteps = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            MeshGradient(width: 2, height: 2, points: [
                                [0, 0], [1, 0],
                                [0, 1], [1, 1],
                            ], colors: [
                                .pink, .indigo,
                                .indigo, .blue,
                            ])
                        )
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                    Text(.init("Generating fill-in-the-blank for **Image Alchemy**..."))
                        .font(.system(size: 34, weight: .bold))
                        .fontWidth(.expanded)
                        .opacity(show ? 1 : 0)
                }
            }
            
            if !generationSteps.isEmpty && showSteps {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(generationSteps.enumerated()), id: \.element.id) { index, step in
                        stepRow(step: step, index: index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: generationSteps.count)
        .padding(.horizontal, 40)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                show = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                withAnimation(.easeIn(duration: 0.3)) {
                    showSteps = true
                }
            }
        }
    }
    
    private func stepRow(step: GenerationStep, index: Int) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: step.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(knowledgeAccentColor)
                .frame(width: 32, alignment: .leading)
            Text(.init(step.message))
                .font(.body)
                .italic()
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.96)),
            removal: .opacity
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(Double(index) * 0.06), value: generationSteps.count)
    }
}

#Preview("Empty state") {
    NavigationStack {
        FillInTheBlanksView(viewModel: FillInTheBlanksViewModel())
    }
}

#Preview("With sample questions") {
    NavigationStack {
        FillInTheBlanksView(viewModel: FillInTheBlanksViewModel(questions: FillInBlankQuestion.sampleQuestions))
    }
}
