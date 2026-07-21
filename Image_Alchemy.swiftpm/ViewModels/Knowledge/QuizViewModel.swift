import SwiftUI

/// ViewModel for Quiz mode
@MainActor
@Observable
final class QuizViewModel {
    var questions: [QuizQuestion]
    
    var currentIndex = 0
    var selectedAnswers: [Int]
    var isGenerating = false
    var generationError: String?
    var generationSteps: [GenerationStep] = []
    
    private let generator = FlashcardGenerator.shared
    
    var currentQuestion: QuizQuestion? {
        guard currentIndex >= 0, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var hasAnsweredCurrent: Bool {
        guard currentIndex >= 0, currentIndex < selectedAnswers.count else { return false }
        return selectedAnswers[currentIndex] >= 0
    }
    
    var canGoPrevious: Bool { currentIndex > 0 }
    var canGoNext: Bool { currentIndex < questions.count - 1 }
    
    init(questions: [QuizQuestion] = []) {
        self.questions = questions
        self.selectedAnswers = Array(repeating: -1, count: questions.count)
    }
    
    /// Color for the progress dot at the given question index: green = correct, red = wrong, default = unattended.
    func dotColor(for index: Int) -> Color {
        guard index < selectedAnswers.count else { return Color.secondary.opacity(0.3) }
        let answered = selectedAnswers[index]
        if answered < 0 { return Color.secondary.opacity(0.3) }
        guard index < questions.count else { return Color.secondary.opacity(0.3) }
        let correct = questions[index].correctIndex == answered
        return correct ? .green : .red
    }
    
    /// Whether the given option index is selected for the current question.
    func isOptionSelected(_ optionIndex: Int) -> Bool {
        guard currentIndex >= 0, currentIndex < selectedAnswers.count else { return false }
        return selectedAnswers[currentIndex] == optionIndex
    }
    
    func selectOption(_ index: Int) {
        guard !hasAnsweredCurrent else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedAnswers[currentIndex] = index
        }
    }
    
    func goToPrevious() {
        guard canGoPrevious else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex -= 1
        }
    }
    
    func goToNext() {
        guard canGoNext else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex += 1
        }
    }

    // MARK: - Foundation Models Integration

    /// Helper to add a generation step with a delay, so steps appear one by one.
    private func addStepWithDelay(_ step: GenerationStep, delay: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            generationSteps.append(step)
        }
    }

    /// Generate quiz questions using the on-device Foundation Model.
    /// - Parameters:
    ///   - topic: Optional narrower topic to focus questions on.
    ///   - forceRefresh: When `true`, discards existing questions and fetches new ones.
    func generateQuizWithAI(topic: String? = nil, forceRefresh: Bool = false) async {
        guard !isGenerating else { return }

        if !forceRefresh, !questions.isEmpty {
            return
        }

        isGenerating = true
        generationError = nil
        questions = []
        selectedAnswers = []
        currentIndex = 0
        generationSteps = []

        // Initial generation step (appears after a short delay)
        await addStepWithDelay(
            GenerationStep(
                message: "Spinning up the **quiz lab**...",
                icon: "brain.head.profile"
            ),
            delay: 1.0
        )
        
        // Add contextual setup steps with delays so they appear one by one
        await addStepWithDelay(
            GenerationStep(
                message: "Collecting devious diffusion gotchas...",
                icon: "magnifyingglass"
            ),
            delay: 1.0
        )
        
        await addStepWithDelay(
            GenerationStep(
                message: "Crafting multiple-choice traps (the fun kind)...",
                icon: "list.bullet.rectangle"
            ),
            delay: 0.7
        )
        
        await addStepWithDelay(
            GenerationStep(
                message: "Writing wrong answers that look suspiciously right...",
                icon: "pencil.and.list.clipboard"
            ),
            delay: 0.7
        )
        
        await addStepWithDelay(
            GenerationStep(
                message: "Brewing instant feedback potions...",
                icon: "sparkles"
            ),
            delay: 0.6
        )

        do {
            var lastReportedCount = 0

            try await generator.generateQuizQuestionsStream(
                topic: topic,
                onUpdate: { [weak self] newQuestions in
                    guard let self else { return }
                    self.questions = newQuestions
                    // Preserve existing answers when new questions are streamed in
                    let keepCount = min(self.selectedAnswers.count, newQuestions.count)
                    let preserved = Array(self.selectedAnswers.prefix(keepCount))
                    let newSlots = Array(repeating: -1, count: newQuestions.count - keepCount)
                    self.selectedAnswers = preserved + newSlots

                     // Add a step when a new question is completed
                    if newQuestions.count > lastReportedCount {
                        lastReportedCount = newQuestions.count

                        if let newQuestion = newQuestions.last {
                            // Extract a short, meaningful snippet from the question
                            let questionText = newQuestion.question
                            let shortSnippet = String(questionText.prefix(50))
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .replacingOccurrences(of: "?", with: "")
                            
                            self.generationSteps.append(
                                GenerationStep(
                                    message: "Question \(newQuestions.count): Crafting **\(shortSnippet)**...",
                                    icon: "questionmark.circle.fill"
                                )
                            )
                        }
                    }

                    if self.currentIndex >= self.questions.count {
                        self.currentIndex = max(0, self.questions.count - 1)
                    }
                }
            )

            if !questions.isEmpty {
                generationSteps.append(
                    GenerationStep(
                        message: "All set! **\(questions.count)** quiz questions ready. Time to test your diffusion knowledge!",
                        icon: "checkmark.circle.fill"
                    )
                )
            }
        } catch {
            generationError = "Could not generate quiz questions. Make sure Apple Intelligence is available and try again."
            generationSteps.append(
                GenerationStep(
                    message: "Quiz generation failed. The AI got stage fright. Try again?",
                    icon: "exclamationmark.triangle.fill"
                )
            )
        }

        isGenerating = false
    }
}
