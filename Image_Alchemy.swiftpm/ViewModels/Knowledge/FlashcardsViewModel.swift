import SwiftUI

/// ViewModel for Flashcards mode
@MainActor
@Observable
final class FlashcardsViewModel {
    var flashcards: [Flashcard]
    
    private let generator = FlashcardGenerator.shared
    
    var currentIndex = 0
    var isFlipped = false
    var isGenerating = false
    var generationError: String?
    
    /// Steps shown during generation to provide user feedback (similar to `lookupHistory` in ItineraryPlanner).
    var generationSteps: [GenerationStep] = []
    
    var currentCard: Flashcard? {
        guard currentIndex >= 0, currentIndex < flashcards.count else { return nil }
        return flashcards[currentIndex]
    }
    
    var canGoPrevious: Bool { currentIndex > 0 }
    var canGoNext: Bool { currentIndex < flashcards.count - 1 }
    
    init(flashcards: [Flashcard] = []) {
        self.flashcards = flashcards
    }
    
    func goToPrevious() {
        guard canGoPrevious else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            isFlipped = false
            currentIndex -= 1
        }
    }
    
    func goToNext() {
        guard canGoNext else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            isFlipped = false
            currentIndex += 1
        }
    }

    // MARK: - Foundation Models Integration

    /// Generate a fresh set of flashcards using the on-device Foundation Model.
    /// - Parameters:
    ///   - topic: Optional narrower topic (e.g. "forward process" or "noise schedule").
    ///   - forceRefresh: When `true`, discards any existing cards and fetches new ones.
    ///     When `false`, if cards already exist, the call is ignored.
    func generateFlashcardsWithAI(topic: String? = nil, forceRefresh: Bool = false) async {
        guard !isGenerating else { return }
        
        // If we already have cards and this isn't an explicit refresh request,
        // don't hit the model again.
        if !forceRefresh, !flashcards.isEmpty {
            return
        }

        isGenerating = true
        generationError = nil
        flashcards = []
        generationSteps = []
        currentIndex = 0
        isFlipped = false

        // Initial generation step (appears immediately)
        await addStepWithDelay(
            GenerationStep(
                message: "Spinning up the **Image Alchemy** lab...",
                icon: "doc.text.magnifyingglass"
            ),
            delay: 1.0
        )
        
        // Add contextual concept extraction + setup steps with delays so they appear one by one
        await addStepWithDelay(
            GenerationStep(
                message: "Tracking loose photons in diffusion space...",
                icon: "brain.head.profile"
            ),
            delay: 1.0
        )
        
        await addStepWithDelay(
            GenerationStep(
                message: "Enchanting blank cards with diffusion magic...",
                icon: "rectangle.stack"
            ),
            delay: 0.7
        )
        
        await addStepWithDelay(
            GenerationStep(
                message: "Hand‑crafting exam tricks so future‑you can brag...",
                icon: "pencil.and.outline"
            ),
            delay: 0.7
        )

        do {
            let targetCount = 10
            var lastReportedCount = 0
            var conceptNames: [String] = []
            
            try await generator.generateFlashcardsStream(
                topic: topic,
                count: targetCount,
                onUpdate: { [weak self] newCards in
                    guard let self else { return }
                    self.flashcards = newCards

                    // Add step when a new card is completed with personalized concept name
                    if newCards.count > lastReportedCount && newCards.count <= targetCount {
                        lastReportedCount = newCards.count
                        
                        // Extract concept name from the term (first few words)
                        let newCard = newCards[newCards.count - 1]
                        let conceptName = String(newCard.term.prefix(40)).trimmingCharacters(in: .whitespacesAndNewlines)
                        conceptNames.append(conceptName)
                        
                        Task { @MainActor in
                            await self.addStepWithDelay(
                                GenerationStep(
                                    message: "Carving a new card for **\(conceptName)**...",
                                    icon: "rectangle.stack.badge.plus"
                                ),
                                delay: 0.2
                            )
                        }
                    }

                    if self.currentIndex >= self.flashcards.count {
                        self.currentIndex = max(0, self.flashcards.count - 1)
                    }
                }
            )
            
            // Final completion step
            if !flashcards.isEmpty {
                await addStepWithDelay(
                    GenerationStep(
                        message: "All set! \(flashcards.count) diffusion cards crafted. Time to level up.",
                        icon: "checkmark.circle.fill"
                    ),
                    delay: 0.3
                )
            }
        } catch {
            generationError = "Could not generate flashcards. Make sure Apple Intelligence is available and try again."
            generationSteps.append(GenerationStep(
                message: "Generation failed. Please try again.",
                icon: "exclamationmark.triangle.fill"
            ))
        }

        isGenerating = false
    }
    
    /// Add a generation step with a delay to create staggered appearance
    private func addStepWithDelay(_ step: GenerationStep, delay: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            generationSteps.append(step)
        }
    }
}
