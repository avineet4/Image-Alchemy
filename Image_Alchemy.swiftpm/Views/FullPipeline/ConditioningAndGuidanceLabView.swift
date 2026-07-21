import SwiftUI

/// Conditioning & Guidance lab: matches the glass, card-based layout of other labs.
struct ConditioningAndGuidanceLabView: View {
    @Binding var prompt: String
    @Binding var guidanceScale: Double

    /// Shared scale from the full pipeline toolbar.
    var architectureScale: CGFloat
    /// Selected area (embeddings / noisy latent); drives expandable bottom sheet content when non-nil.
    @Binding var selectedArea: FullPipelineViewModel.ConditioningLabArea?
    
    @State private var showWords: Bool = false
    @State private var stackWords: Bool = false
    @State private var showEmbeddings: Bool = false
    @State private var showTokens: Bool = true
    @State private var unetStep: Int = 0
    @State private var highlightedCellIndex: Int = -1
    @State private var showCellHighlight: Bool = false

    private var words: [String] {
        prompt.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).map(String.init)
    }

    var body: some View {
        VStack(spacing: 35) {
            // Text("Conditioning")
            //     .font(.title2.weight(.semibold))
            //     .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                if showWords {
                    Group {
                        if stackWords {
                            HStack(spacing: 0) {
                                VStack(spacing: 100) {
                                    VStack(alignment: .trailing, spacing: 8) {
                                        ForEach(words, id: \.self) { word in
                                            HStack(spacing: 40) {
                                                if showTokens {
                                                    VStack(spacing: 12) {
                                                        if word == words.first {
                                                            Text("Tokens")
                                                                .font(.title3)
                                                                .foregroundStyle(.secondary)
                                                        }
                                                        
                                                        Text(word)
                                                            .font(.title3)
                                                            .padding(16)
                                                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                                                    }
                                                    .transition(.asymmetric(
                                                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                                        removal: .opacity.combined(with: .scale(scale: 0.96))
                                                    ))
                                                }
                                                
                                                if showEmbeddings {
                                                    VStack(spacing: 10) {
                                                        if word == words.first {
                                                            Text("Embeddings")
                                                                .font(.title3)
                                                                .foregroundStyle(.secondary)
                                                                .offset(y: -15)
                                                        }
                                                        
                                                        HStack(spacing: 4) {
                                                            ForEach(0..<10, id: \.self) { barIndex in
                                                                RoundedRectangle(cornerRadius: 3)
                                                                    .fill(Color.primary.opacity(seededValue(i: barIndex, seed: word)))
                                                                    .frame(width: 10, height: 24)
                                                                    .overlay {
                                                                        if showCellHighlight && (highlightedCellIndex % 10) == barIndex {
                                                                            RoundedRectangle(cornerRadius: 3)
                                                                                .stroke(Color.yellow, lineWidth: 2)
                                                                        }
                                                                    }
                                                            }
                                                        }
                                                    }
                                                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                                                    .contentShape(.rect)
                                                    .onTapGesture { selectedArea = .embeddings }
                                                }
                                            }
                                        }
                                    }
                                        
                                    if !showTokens {
                                        VStack(spacing: 26) {
                                            Text("Noisy latent zₜ")
                                                .font(.title3)
                                                .foregroundStyle(.secondary)
                                                
                                            LazyVGrid(
                                                columns: Array(repeating: GridItem(.fixed(10), spacing: 4), count: 10),
                                                spacing: 8
                                            ) {
                                                ForEach(0..<60, id: \.self) { i in
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .fill(Color.primary.opacity(0.1 + 0.8 * (Double((i * 5 + 7) % 13) / 13.0)))
                                                        .frame(width: 10, height: 24)
                                                        .overlay {
                                                            if showCellHighlight && highlightedCellIndex == i {
                                                                RoundedRectangle(cornerRadius: 2)
                                                                    .stroke(Color.yellow, lineWidth: 2)
                                                            }
                                                        }
                                                }
                                            }
                                        }
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .scale(scale: 0.94)).combined(with: .offset(x: -20)),
                                            removal: .opacity.combined(with: .scale(scale: 0.96))
                                        ))
                                        .contentShape(.rect)
                                        .onTapGesture { selectedArea = .noisyLatent }
                                    }
                                }

                                if !showTokens {
                                    UNetStepVisualization(
                                        step: unetStep,
                                        showCellHighlight: showCellHighlight,
                                        highlightedCellIndex: highlightedCellIndex
                                    )
                                        .frame(maxWidth: 520)
                                        .scaleEffect(1.3)
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                                            removal: .opacity
                                        ))
                                        .contentShape(.rect)
                                        .onTapGesture { selectedArea = .unet }

                                    VStack(spacing: 8) {
                                        Text("Noise prediction εᶿ")
                                            .font(.title3)
                                            .foregroundStyle(.secondary)
                                        LazyVGrid(
                                            columns: Array(repeating: GridItem(.fixed(10), spacing: 4), count: 10),
                                            spacing: 8
                                        ) {
                                            ForEach(0..<60, id: \.self) { i in
                                                let isRevealed = showCellHighlight && i <= highlightedCellIndex
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(isRevealed ? Color.primary.opacity(0.15 + 0.7 * (Double((i + 3) % 7 + i / 10) / 10)) : Color.clear)
                                                    .frame(width: 10, height: 24)
                                                    .overlay {
                                                        if showCellHighlight && highlightedCellIndex == i {
                                                            RoundedRectangle(cornerRadius: 2)
                                                                .stroke(Color.yellow, lineWidth: 2)
                                                        }
                                                    }
                                            }
                                        }
                                        .padding(8)
                                    }
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.94)).combined(with: .offset(x: 20)),
                                        removal: .opacity
                                    ))
                                    .contentShape(.rect)
                                    .onTapGesture { selectedArea = .noisePrediction }
                                }
                            }
                            .transition(.opacity)
                        } else {
                            VStack(spacing: 12) {
                                Text("Tokens")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 8) {
                                    ForEach(words, id: \.self) { word in
                                        Text(word)
                                            .font(.title3)
                                            .padding(16)
                                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                                    }
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    Text("Prompt")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text(prompt)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding(20)
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                }
            }
            .animation(.smooth(duration: 0.85), value: showWords)
            .animation(.smooth(duration: 1.1), value: stackWords)
            .animation(.smooth(duration: 0.75), value: showEmbeddings)
            .animation(.smooth(duration: 0.85), value: showTokens)
            .animation(.smooth(duration: 0.65), value: unetStep)
            .animation(.smooth(duration: 0.2), value: highlightedCellIndex)
            .animation(.smooth(duration: 0.35), value: showCellHighlight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .scaleEffect(architectureScale)
        .task {
            // Phase 1: Hold full prompt, then reveal token words
            try? await Task.sleep(nanoseconds: UInt64(0.9 * 1_000_000_000))
            // Delay after Prompt before showing Tokens
            try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
            withAnimation(.smooth(duration: 0.85)) {
                showWords = true
            }
            // Delay after Tokens (simple HStack) before restacking
            try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
            // Phase 2: Restack words vertically (give transition time to finish)
            try? await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))
            withAnimation(.smooth(duration: 0.5)) {
                stackWords = true
            }
            // Phase 3: Reveal embeddings with a short stagger delay
            try? await Task.sleep(nanoseconds: UInt64(0.85 * 1_000_000_000))
            withAnimation(.smooth(duration: 0.75)) {
                showEmbeddings = true
            }
            // Phase 4: Fade out tokens; noisy latent, U-Net, and noise prediction transition in
            try? await Task.sleep(nanoseconds: UInt64(1.5 * 1_000_000_000))
            withAnimation(.smooth(duration: 0.85)) {
                showTokens = false
            }
            // Phase 5: Wait for U-Net (and layout) to complete its transition, then U-Net steps
            try? await Task.sleep(nanoseconds: UInt64(0.9 * 1_000_000_000))
            for stepIndex in 0..<4 {
                try? await Task.sleep(nanoseconds: UInt64(0.2 * 1_000_000_000))
                withAnimation(.smooth(duration: 0.2)) {
                    unetStep = stepIndex
                }
            }
            // Phase 6: Pause so U-Net rotation/transition is fully settled, then cell highlight traversal
            try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
            withAnimation(.smooth(duration: 0.35)) {
                showCellHighlight = true
            }
            try? await Task.sleep(nanoseconds: UInt64(0.15 * 1_000_000_000))
            for i in 0..<60 {
                withAnimation(.smooth(duration: 0.18)) {
                    highlightedCellIndex = i
                }
                try? await Task.sleep(nanoseconds: 175_000_000)
            }
        }
    }
}

private func seededValue(i: Int, seed: String) -> Double {
    // Strong hash of the seed (FNV-1a inspired)
    var hash: UInt64 = 1469598103934665603
    for scalar in seed.unicodeScalars {
        hash ^= UInt64(scalar.value)
        hash &*= 1099511628211
    }
    
    // Mix with index using SplitMix64-style scrambling
    var x = UInt64(bitPattern: Int64(i)) &+ hash
    x ^= x >> 30
    x &*= 0xbf58476d1ce4e5b9
    x ^= x >> 27
    x &*= 0x94d049bb133111eb
    x ^= x >> 31
    
    // Convert to [0, 1]
    let normalized = Double(x) / Double(UInt64.max)
    
    // Scale to [0.15, 0.85]
    return 0.15 + 0.7 * normalized
}

private struct UNetStepVisualization: View {
    let step: Int
    var showCellHighlight: Bool = false
    var highlightedCellIndex: Int = -1

    private static let traversalOrder: [Int] = [
        0, 1, 2,           // row 0: 0, 1, 2
        6, 7, 8,          // row 1: 0, 1, 2
        12, 13, 14,       // row 2: 0, 1, 2
        18, 19, 20,       // row 3: 0, 1, 2
        24, 25, 26,       // bottom
        21, 22, 23,       // row 3: 3, 4, 5
        15, 16, 17,       // row 2: 3, 4, 5
        9, 10, 11,        // row 1: 3, 4, 5
        3, 4, 5           // row 0: 3, 4, 5
    ]
    private var currentHighlightedBarIndex: Int {
        guard showCellHighlight, highlightedCellIndex >= 0 else { return -1 }
        let step = min((highlightedCellIndex * Self.traversalOrder.count) / 60, Self.traversalOrder.count - 1)
        return Self.traversalOrder[step]
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("U-Net")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 20) {
                unetRow(leftCount: 3, rightCount: 3, lineWidth: 300, height: 60, barWidth: 5, startIndex: 0)
                unetRow(leftCount: 3, rightCount: 3, lineWidth: 250, height: 47, barWidth: 7, startIndex: 6)
                unetRow(leftCount: 3, rightCount: 3, lineWidth: 190, height: 35, barWidth: 9, startIndex: 12)
                unetRow(leftCount: 3, rightCount: 3, lineWidth: 100, height: 25, barWidth: 11, startIndex: 18)
                bottomRow(lineWidth: 120, height: 15, barWidth: 13, startIndex: 24)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 26)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func unetRow(leftCount: Int, rightCount: Int, lineWidth: CGFloat, height: CGFloat, barWidth: CGFloat, startIndex: Int) -> some View {
        HStack(alignment: .center, spacing: 32) {
            barGroup(count: leftCount, height: height, barWidth: barWidth, startIndex: startIndex)

            HStack(spacing: -2) {
                Rectangle()
                    .fill(.primary)
                    .frame(width: lineWidth, height: 2)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            barGroup(count: rightCount, height: height, barWidth: barWidth, startIndex: startIndex + leftCount)
        }
    }

    private func bottomRow(lineWidth: CGFloat, height: CGFloat, barWidth: CGFloat, startIndex: Int) -> some View {
        HStack(alignment: .center, spacing: 24) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    let barIndex = startIndex + index
                    RoundedRectangle(cornerRadius: 3)
                        .fill(bottomBlockColor(index: index))
                        .frame(width: barWidth, height: height)
                        .overlay {
                            if showCellHighlight && barIndex == currentHighlightedBarIndex {
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color.yellow, lineWidth: 4)
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                            }
                        }
                }
            }

            // HStack(spacing: 4) {
            //     Rectangle()
            //         .fill(Color(#colorLiteral(red: 0.18, green: 0.29, blue: 0.63, alpha: 1.0)))
            //         .frame(width: lineWidth, height: 2)
            //     Image(systemName: "arrow.right")
            //         .font(.caption2.weight(.semibold))
            //         .foregroundStyle(Color(#colorLiteral(red: 0.18, green: 0.29, blue: 0.63, alpha: 1.0)))
            // }
        }
    }

    private func barGroup(count: Int, height: CGFloat, barWidth: CGFloat, startIndex: Int) -> some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                let barIndex = startIndex + index
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor(index: index))
                    .frame(width: barWidth, height: height)
                    .overlay {
                        if showCellHighlight && barIndex == currentHighlightedBarIndex {
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(Color.yellow, lineWidth: 4)
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                        }
                    }
            }
        }
    }

    private func barColor(index: Int) -> Color {
        index.isMultiple(of: 2)
            ? Color(#colorLiteral(red: 0.18, green: 0.29, blue: 0.82, alpha: 1.0))
            : Color(#colorLiteral(red: 0.0, green: 0.74, blue: 0.75, alpha: 1.0))
    }

    private func bottomBlockColor(index: Int) -> Color {
        index.isMultiple(of: 2)
            ? Color(#colorLiteral(red: 0.0, green: 0.74, blue: 0.75, alpha: 1.0))
            : Color(#colorLiteral(red: 0.18, green: 0.29, blue: 0.82, alpha: 1.0))
    }
}

#Preview {
    StatefulPreviewWrapper(
        initialPrompt: "A tropical beach with white sand",
        initialGuidanceScale: 7.0
    )
}

/// Simple state holder so we can preview bindings.
private struct StatefulPreviewWrapper: View {
    @State private var prompt: String
    @State private var guidanceScale: Double

    init(
        initialPrompt: String,
        initialGuidanceScale: Double
    ) {
        _prompt = State(initialValue: initialPrompt)
        _guidanceScale = State(initialValue: initialGuidanceScale)
    }

    var body: some View {
        ConditioningAndGuidanceLabView(
            prompt: $prompt,
            guidanceScale: $guidanceScale,
            architectureScale: 1.0,
            selectedArea: .constant(nil)
        )
        .padding()
    }
}

