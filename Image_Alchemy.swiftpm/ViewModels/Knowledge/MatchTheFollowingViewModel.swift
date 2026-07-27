import SwiftUI

/// ViewModel for Match the Following mode
@MainActor
@Observable
final class MatchTheFollowingViewModel: KnowledgeGenerationModel {
    var pairs: [MatchPair]

    /// Left column text during streaming (one per row); cleared when generation finishes.
    var streamingLeftItems: [String] = []
    /// Right column text during streaming (same count as left); "..." when not yet received.
    var streamingRightItems: [String] = []

    var rightItems: [String]
    var userMatches: [Int: Int] = [:]
    var selectedLeftIndex: Int?
    var hasChecked = false
    var isGenerating = false
    var generationError: String?
    var generationSteps: [GenerationStep] = []
    
    private let generator = FlashcardGenerator.shared
    /// Throttle streaming UI updates so we don’t redraw on every token.
    private var lastStreamingUpdateTime: Date = .distantPast
    private var lastStreamingCount: Int = 0
    private let streamingThrottleInterval: TimeInterval = 0.12

    var allMatched: Bool { userMatches.count == pairs.count }
    
    var correctCount: Int {
        guard hasChecked else { return 0 }
        return (0..<pairs.count).filter { leftIdx in
            guard let userRightIdx = userMatches[leftIdx] else { return false }
            return rightItems[userRightIdx] == pairs[leftIdx].rightItem
        }.count
    }
    
    init(pairs: [MatchPair] = []) {
        self.pairs = pairs
        self.rightItems = pairs.map(\.rightItem).shuffled()
    }
    
    func selectLeft(_ index: Int) {
        guard !hasChecked, !isGenerating else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedLeftIndex = selectedLeftIndex == index ? nil : index
        }
    }
    
    func selectRight(_ index: Int) {
        guard !hasChecked, !isGenerating, let leftIndex = selectedLeftIndex else { return }
        setMatch(leftIndex: leftIndex, rightIndex: index)
    }
    
    /// Set a match (used by both tap-to-match and drag-and-drop). Clears conflicts and selection.
    func setMatch(leftIndex: Int, rightIndex: Int) {
        guard !hasChecked, !isGenerating else { return }
        guard (0..<pairs.count).contains(leftIndex), (0..<rightItems.count).contains(rightIndex) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let keysToClear = userMatches.filter { $0.value == rightIndex && $0.key != leftIndex }.map(\.key)
            for k in keysToClear { userMatches[k] = nil }
            userMatches[leftIndex] = rightIndex
            selectedLeftIndex = nil
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func checkAnswer() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasChecked = true
        }
    }
    
    /// Whether the left item at the given index was matched correctly (after check).
    func isCorrectMatch(at leftIndex: Int) -> Bool {
        guard let rightIdx = userMatches[leftIndex] else { return false }
        return rightItems[rightIdx] == pairs[leftIndex].rightItem
    }
    
    /// Whether the left item at the given index was matched incorrectly (after check).
    func isIncorrectMatch(at leftIndex: Int) -> Bool {
        userMatches[leftIndex] != nil && !isCorrectMatch(at: leftIndex)
    }
    
    /// Whether the right item at the given index is currently selected (matches the selected left).
    func isRightItemSelected(_ rightIndex: Int) -> Bool {
        guard let leftIdx = selectedLeftIndex else { return false }
        return userMatches[leftIdx] == rightIndex
    }

    // MARK: - Foundation Models Integration

    /// Helper to add a generation step with a delay, so steps appear one by one.
    /// Generate match pairs using the on-device Foundation Model.
    /// - Parameters:
    ///   - topic: Optional narrower topic to focus pairs on.
    ///   - forceRefresh: When `true`, discards existing pairs and fetches new ones.
    func generateMatchPairsWithAI(topic: String? = nil, forceRefresh: Bool = false) async {
        guard !isGenerating else { return }

        if !forceRefresh, !pairs.isEmpty {
            return
        }

        isGenerating = true
        generationError = nil
        pairs = []
        streamingLeftItems = []
        streamingRightItems = []
        lastStreamingUpdateTime = .distantPast
        lastStreamingCount = 0
        rightItems = []
        userMatches = [:]
        selectedLeftIndex = nil
        hasChecked = false
        generationSteps = []

        // Initial generation step (appears immediately)
        await addGenerationStep(
            GenerationStep(
                message: "Spinning up the **match lab**...",
                icon: "arrow.left.arrow.right.circle"
            ), 
            after: 1.0
        )
        await addGenerationStep(
            GenerationStep(
                message: "Collecting term–definition pairs from diffusion concepts...",
                icon: "magnifyingglass"
            ),
            after: 1.0
        )
        await addGenerationStep(
            GenerationStep(
                message: "Shuffling definitions so nothing is too easy...",
                icon: "shuffle"
            ),
            after: 0.7
        )
        await addGenerationStep(
            GenerationStep(
                message: "Drawing connection lines (metaphorically)...",
                icon: "line.diagonal"
            ),
            after: 0.7
        )

        var lastReportedCount = 0

        do {
            try await generator.generateMatchPairsStream(
                topic: topic,
                count: 8,
                onUpdate: { [weak self] partialPairs in
                guard let self else { return }

                // Helper to check if a definition appears complete (not truncated)
                func isDefinitionComplete(_ text: String?) -> Bool {
                    guard let text = text, !text.isEmpty else { return false }
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Must have reasonable length
                    guard trimmed.count >= 15 else { return false }
                    
                    // Should end with proper punctuation
                    if trimmed.last == "." || trimmed.last == "!" || trimmed.last == "?" {
                        return true
                    }
                    
                    // Check for incomplete endings
                    let lowercased = trimmed.lowercased()
                    let incompleteEndings = [" the", " a ", " an ", " of ", " in ", " on ", " at ", " to ", " for "]
                    if incompleteEndings.contains(where: { lowercased.hasSuffix($0) }) {
                        return false
                    }
                    
                    // Allow longer definitions even without punctuation if they're substantial
                    return trimmed.count >= 30
                }

                let newPairs: [MatchPair] = partialPairs.compactMap { partial in
                    guard
                        let leftItem = partial.leftItem,
                        !leftItem.isEmpty,
                        let rightItem = partial.rightItem,
                        isDefinitionComplete(rightItem)
                    else {
                        return nil
                    }
                    return MatchPair(leftItem: leftItem, rightItem: rightItem)
                }
                // Streaming UI and final snapshot on MainActor
                let lefts = partialPairs.map { p in
                    (p.leftItem?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? "..."
                }
                let rights = partialPairs.map { p in
                    (p.rightItem?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s }
                        ?? (p.leftItem != nil ? "..." : "")
                }
                Task { @MainActor in
                    let countIncreased = lefts.count > self.lastStreamingCount
                    let throttlePassed = Date().timeIntervalSince(self.lastStreamingUpdateTime) >= self.streamingThrottleInterval
                    if countIncreased || throttlePassed {
                        self.lastStreamingUpdateTime = Date()
                        self.lastStreamingCount = lefts.count
                        self.streamingLeftItems = lefts
                        self.streamingRightItems = rights
                    }
                }

                if newPairs.count > lastReportedCount, let newPair = newPairs.last {
                    lastReportedCount = newPairs.count
                    let termSnippet = String(newPair.leftItem.prefix(40)).trimmingCharacters(in: .whitespacesAndNewlines)
                    Task { @MainActor in
                        self.generationSteps.append(GenerationStep(
                            message: "Pair \(newPairs.count): **\(termSnippet)** ↔ definition...",
                            icon: "arrow.left.arrow.right"
                        ))
                    }
                }
            },
                onComplete: { [weak self] partialPairs in
                    guard let self else { return }
                    Task { @MainActor in
                        let trimmed = { (s: String) in s.trimmingCharacters(in: .whitespacesAndNewlines) }
                        let complete = partialPairs.compactMap { partial -> MatchPair? in
                            guard
                                let left = partial.leftItem.map(trimmed), !left.isEmpty,
                                let right = partial.rightItem.map(trimmed), !right.isEmpty,
                                right.count >= 10,
                                [".", "!", "?"].contains(where: { right.hasSuffix($0) }) || right.count >= 20
                            else { return nil }
                            return MatchPair(leftItem: left, rightItem: right)
                        }
                        self.pairs = complete
                        self.rightItems = complete.map(\.rightItem).shuffled()
                        self.streamingLeftItems = []
                        self.streamingRightItems = []
                        if complete.count >= 2 {
                            self.generationError = nil
                            self.generationSteps.append(GenerationStep(
                                message: "All set! **\(self.pairs.count)** pairs ready. Match away.",
                                icon: "checkmark.circle.fill"
                            ))
                        } else if complete.count == 1 {
                            self.generationError = "Only 1 pair was generated. Tap \"Generate with AI\" again for more pairs."
                        }
                        self.isGenerating = false
                    }
                }
            )
        } catch {
            generationError = "Could not generate match pairs. Make sure Apple Intelligence is available and try again."
            generationSteps.append(GenerationStep(
                message: "Match generation failed. Please try again.",
                icon: "exclamationmark.triangle.fill"
            ))
        }

        isGenerating = false
    }
}
