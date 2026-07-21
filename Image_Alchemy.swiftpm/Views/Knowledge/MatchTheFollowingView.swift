import SwiftUI

struct MatchTheFollowingView: View {
    @Bindable var viewModel: MatchTheFollowingViewModel
    @State private var itemFrames: [MatchItemFrame] = []
    @State private var contentRevealed = false
    @State private var resultAppearCount = 0
    @State private var lineReveal: Double = 1
    
    var body: some View {
        Group {
            if viewModel.isGenerating && viewModel.pairs.isEmpty && viewModel.streamingLeftItems.isEmpty {
                MatchTheFollowingGeneratingView(generationSteps: viewModel.generationSteps)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.pairs.isEmpty && !viewModel.isGenerating {
                MatchTheFollowingEmptyStateView(
                    isGenerating: viewModel.isGenerating,
                    error: viewModel.generationError
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Single branch: streaming or game - same layout so completion doesn’t refresh
                VStack(alignment: .center, spacing: 24) {
                    instructionHeader
                    unifiedMatchSection
                    if let error = viewModel.generationError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    Spacer(minLength: 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .animation(.easeOut(duration: 0.25), value: viewModel.hasChecked)
                .onAppear {
                    if !viewModel.pairs.isEmpty || !viewModel.streamingLeftItems.isEmpty {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            contentRevealed = true
                        }
                    }
                }
                .onChange(of: viewModel.pairs.count) { _, _ in
                    if (!viewModel.pairs.isEmpty || !viewModel.streamingLeftItems.isEmpty) && !contentRevealed {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            contentRevealed = true
                        }
                    }
                }
                .onChange(of: viewModel.streamingLeftItems.isEmpty) { _, isEmpty in
                    if !isEmpty && !contentRevealed {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            contentRevealed = true
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Match the Following")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Show reset only when we have pairs and we're not generating
                if !viewModel.isGenerating && !viewModel.pairs.isEmpty {
                    Button {
                        lineReveal = 1
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                            viewModel.pairs = []
                            viewModel.rightItems = []
                            viewModel.streamingLeftItems = []
                            viewModel.streamingRightItems = []
                            viewModel.generationSteps = []
                            viewModel.userMatches = [:]
                            viewModel.selectedLeftIndex = nil
                            viewModel.hasChecked = false
                            viewModel.generationError = nil
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                
                Button {
                    Task {
                        await viewModel.generateMatchPairsWithAI(forceRefresh: true)
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
    
    private var instructionHeader: some View {
        VStack(alignment: .center, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(knowledgeAccentColor)
                    .symbolEffect(.variableColor.iterative.reversing, options: .repeating.speed(0.5))
                Text("Match each term with its correct definition")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("Tap a term, then tap its definition")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .opacity(contentRevealed ? 1 : 0)
        .offset(y: contentRevealed ? 0 : 10)
        .animation(.smooth(duration: 0.4), value: contentRevealed)
    }
    
    private var unifiedMatchSection: some View {
        let isStreaming = viewModel.isGenerating && !viewModel.streamingLeftItems.isEmpty
        let rowCount = isStreaming ? viewModel.streamingLeftItems.count : viewModel.pairs.count

        return VStack(spacing: 12) {
            ForEach(0..<rowCount, id: \.self) { index in
                unifiedMatchRow(index: index, isStreaming: isStreaming)
            }

            if !isStreaming {
                if viewModel.hasChecked {
                    HStack(spacing: 12) {
                        resultSection
                        if viewModel.correctCount != viewModel.pairs.count {
                            Button {
                                lineReveal = 1
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                    viewModel.userMatches = [:]
                                    viewModel.selectedLeftIndex = nil
                                    viewModel.hasChecked = false
                                    viewModel.generationError = nil
                                }
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
                    .padding(.top, 32)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                if viewModel.allMatched && !viewModel.hasChecked && !viewModel.isGenerating {
                    checkAnswerButton
                        .padding(.top, 32)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .coordinateSpace(name: "matchArea")
        .overlay(
            Group {
                if !isStreaming {
                    MatchLinesOverlay(
                        userMatches: viewModel.userMatches,
                        itemFrames: itemFrames,
                        hasChecked: viewModel.hasChecked,
                        pairs: viewModel.pairs,
                        rightItems: viewModel.rightItems,
                        lineReveal: lineReveal
                    )
                }
            }
        )
        .onPreferenceChange(MatchFramePreferenceKey.self) { itemFrames = $0 }
        .onChange(of: viewModel.userMatches.count) { _, newCount in
            guard newCount > 0 else { return }
            lineReveal = 0
            withAnimation(.easeOut(duration: 0.4)) {
                lineReveal = 1
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        )
        .opacity(contentRevealed ? 1 : 0)
        .offset(y: contentRevealed ? 0 : 20)
        .animation(.smooth(duration: 0.4), value: contentRevealed)
        .animation(.smooth(duration: 0.35), value: isStreaming)
        .animation(.smooth(duration: 0.3), value: rowCount)
    }

    @ViewBuilder
    private func unifiedMatchRow(index: Int, isStreaming: Bool) -> some View {
        let inBounds = isStreaming
            ? index < viewModel.streamingLeftItems.count
            : index < viewModel.pairs.count && index < viewModel.rightItems.count
        if inBounds {
            let leftText = isStreaming
                ? viewModel.streamingLeftItems[index]
                : viewModel.pairs[index].leftItem
            let rightText = isStreaming
                ? (index < viewModel.streamingRightItems.count ? viewModel.streamingRightItems[index] : "...")
                : viewModel.rightItems[index]

            HStack(alignment: .top, spacing: 0) {
                MatchItemView(
                    label: String(UnicodeScalar(65 + index)!),
                    text: leftText,
                    isSelected: isStreaming ? false : (viewModel.selectedLeftIndex == index),
                    isCorrect: isStreaming ? false : (viewModel.hasChecked && viewModel.isCorrectMatch(at: index)),
                    isIncorrect: isStreaming ? false : (viewModel.hasChecked && viewModel.isIncorrectMatch(at: index))
                ) {
                    if !isStreaming { viewModel.selectLeft(index) }
                }
                .background(framePreference(isLeft: true, index: index))
                .frame(maxWidth: 280)
                .opacity(contentRevealed ? 1 : 0)
                .offset(x: contentRevealed ? 0 : (isStreaming ? 0 : -20))
                .animation(.smooth(duration: 0.35).delay(Double(index) * 0.04), value: contentRevealed)
                .animation(.smooth(duration: 0.25), value: viewModel.hasChecked)

                Spacer(minLength: 24)

                MatchItemView(
                    label: "\(index + 1)",
                    text: rightText,
                    isSelected: isStreaming ? false : viewModel.isRightItemSelected(index),
                    isCorrect: false,
                    isIncorrect: false
                ) {
                    if !isStreaming { viewModel.selectRight(index) }
                }
                .id(isStreaming ? "streaming-\(index)" : viewModel.rightItems[index])
                .background(framePreference(isLeft: false, index: index))
                .frame(maxWidth: 520)
                .opacity(contentRevealed ? 1 : 0)
                .offset(x: contentRevealed ? 0 : (isStreaming ? 0 : 20))
                .animation(.smooth(duration: 0.35).delay(Double(index) * 0.04), value: contentRevealed)
            }
            .frame(maxWidth: .infinity)
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
        .opacity(contentRevealed ? 1 : 0)
        .offset(y: contentRevealed ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.35), value: contentRevealed)
    }

    private var resultSection: some View {
        let total = max(viewModel.pairs.count, 1)
        let correct = viewModel.correctCount
        let score = Double(correct) / Double(total)
        let allCorrect = correct == total
        let allWrong = correct == 0
        _ = !allCorrect && !allWrong

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
                Text("\(correct) of \(total) correct")
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
    
    private func framePreference(isLeft: Bool, index: Int) -> some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .named("matchArea"))
            Color.clear.preference(
                key: MatchFramePreferenceKey.self,
                value: [MatchItemFrame(
                    isLeft: isLeft,
                    index: index,
                    midX: Double(frame.midX),
                    midY: Double(frame.midY),
                    minX: Double(frame.minX),
                    maxX: Double(frame.maxX)
                )]
            )
        }
    }
}

private struct MatchTheFollowingEmptyStateView: View {
    let isGenerating: Bool
    let error: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .foregroundStyle(knowledgeAccentColor)
                .symbolEffect(.pulse.byLayer, options: .repeating)
            
            VStack(spacing: 4) {
                Text(isGenerating ? "Generating pairs…" : "No match pairs yet")
                    .font(.title.weight(.semibold))
                
                Text(isGenerating
                     ? "Creating term–definition pairs from your Image Alchemy walkthrough."
                     : "Generate match-the-following pairs with Apple Intelligence to test your diffusion knowledge.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Label("Based on your Image Alchemy walkthrough", systemImage: "sparkles")
                Label("Drag or tap to connect terms with definitions", systemImage: "arrow.left.arrow.right")
                Label("Instant feedback when you check answers", systemImage: "checkmark.circle")
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

private struct MatchTheFollowingGeneratingView: View {
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
                    Text(.init("Generating match pairs for **Image Alchemy**..."))
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
        MatchTheFollowingView(viewModel: MatchTheFollowingViewModel())
    }
}

#Preview("With sample pairs") {
    NavigationStack {
        MatchTheFollowingView(viewModel: MatchTheFollowingViewModel(pairs: MatchPair.samplePairs))
    }
}
