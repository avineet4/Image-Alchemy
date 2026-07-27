import SwiftUI

/// ViewModel for Fill in the Blanks mode
@MainActor
@Observable
final class FillInTheBlanksViewModel: KnowledgeGenerationModel {
    var questions: [FillInBlankQuestion]
    
    var currentIndex = 0
    var wordBank: [String]
    /// Fills for the current question only. Persisted to userFillsByQuestion when navigating.
    var userFills: [Int: String] = [:]
    /// Per-question filled blanks (question index -> blank index -> word). Preserved when navigating.
    var userFillsByQuestion: [Int: [Int: String]] = [:]
    /// Whether the current question has been checked. Derived from checkedQuestionResults.
    var hasChecked: Bool { checkedQuestionResults[currentIndex] != nil }
    /// Per-question result after check: nil = unattended, true = all correct, false = had wrong blanks.
    var checkedQuestionResults: [Int: Bool] = [:]
    var isGenerating = false
    var generationError: String?
    var generationSteps: [GenerationStep] = []
    
    private let generator = FlashcardGenerator.shared
    
    var currentQuestion: FillInBlankQuestion? {
        guard currentIndex >= 0, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var allBlanksFilled: Bool {
        guard let question = currentQuestion else { return false }
        let blankIndices = question.segments.compactMap { seg -> Int? in
            if case .blank(let i) = seg { return i }
            return nil
        }
        return Set(blankIndices).allSatisfy { userFills[$0] != nil }
    }
    
    var canGoPrevious: Bool { currentIndex > 0 }
    var canGoNext: Bool { currentIndex < questions.count - 1 }
    
    init(questions: [FillInBlankQuestion] = []) {
        self.questions = questions
        self.wordBank = questions.isEmpty ? [] : questions[0].wordBank.shuffled()
    }
    
    /// Color for the progress dot at the given question index: green = correct, red = wrong, default = unattended.
    func dotColor(for index: Int) -> Color {
        guard let result = checkedQuestionResults[index] else { return Color.secondary.opacity(0.3) }
        return result ? .green : .red
    }
    
    func correctCount(for question: FillInBlankQuestion) -> Int {
        question.answers.enumerated().filter { index, answer in
            guard let filled = userFills[index] else { return false }
            return filled.caseInsensitiveCompare(answer) == .orderedSame
        }.count
    }
    
    func placeWord(_ word: String, inBlank index: Int) {
        guard !hasChecked, !isGenerating else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            if let existing = userFills[index] { wordBank.append(existing) }
            userFills[index] = word
            wordBank.removeAll { $0 == word }
        }
    }
    
    func removeFromBlank(_ index: Int) {
        guard !hasChecked, !isGenerating, let word = userFills[index] else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            userFills[index] = nil
            wordBank.append(word)
        }
    }
    
    func checkAnswer() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let question = currentQuestion {
                let correct = correctCount(for: question) == question.answers.count
                checkedQuestionResults[currentIndex] = correct
            }
        }
    }
    
    /// Resets the current question: clears fills, returns all words to the word bank, and clears the check result.
    func resetCurrentQuestion() {
        guard let question = currentQuestion else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            userFillsByQuestion[currentIndex] = [:]
            userFills = [:]
            wordBank = question.wordBank.shuffled()
            checkedQuestionResults[currentIndex] = nil
            generationError = nil
        }
    }
    
    /// Saves current question's fills, then loads state for the given index.
    private func loadQuestionState() {
        guard let question = currentQuestion else { return }
        userFills = userFillsByQuestion[currentIndex] ?? [:]
        let used = Set(userFills.values)
        wordBank = question.wordBank.filter { !used.contains($0) }.shuffled()
    }
    
    func goToPrevious() {
        guard canGoPrevious else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            userFillsByQuestion[currentIndex] = userFills
            currentIndex -= 1
            loadQuestionState()
        }
    }
    
    func goToNext() {
        guard canGoNext else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            userFillsByQuestion[currentIndex] = userFills
            currentIndex += 1
            loadQuestionState()
        }
    }

    // MARK: - Foundation Models Integration

    /// Generate fill-in-the-blank questions using the on-device Foundation Model.
    /// - Parameters:
    ///   - topic: Optional narrower topic to focus questions on.
    ///   - forceRefresh: When `true`, discards existing questions and fetches new ones.
    func generateFillInBlanksWithAI(topic: String? = nil, forceRefresh: Bool = false) async {
        guard !isGenerating else { return }

        if !forceRefresh, !questions.isEmpty {
            return
        }

        isGenerating = true
        generationError = nil
        questions = []
        wordBank = []
        userFills = [:]
        userFillsByQuestion = [:]
        checkedQuestionResults = [:]
        currentIndex = 0
        generationSteps = []

        await addGenerationStep(
            GenerationStep(
                message: "Spinning up the **fill-in-the-blank** lab...",
                icon: "textformat"
            ),
            after: 1.0
        )
        await addGenerationStep(
            GenerationStep(
                message: "Picking key terms from your Image Alchemy walkthrough...",
                icon: "magnifyingglass"
            ),
            after: 1.0
        )
        await addGenerationStep(
            GenerationStep(
                message: "Carving blanks into sentences...",
                icon: "minus.rectangle"
            ),
            after: 0.7
        )
        await addGenerationStep(
            GenerationStep(
                message: "Shuffling the word bank...",
                icon: "shuffle"
            ),
            after: 0.7
        )

        var lastReportedCount = 0

        do {
            // Request 3 so all fit in the on-device model's ~4096-token context window (more causes truncation / single item).
            try await generator.generateFillInBlankQuestionsStream(
                topic: topic,
                count: 3,
                onUpdate: { [weak self] partials in
                    guard let self else { return }
                    let newQuestions = partials.compactMap { self.buildQuestion(from: $0) }
                    if !newQuestions.isEmpty {
                        // Preserve current question's fills when stream adds more questions
                        if self.currentIndex < self.questions.count {
                            self.userFillsByQuestion[self.currentIndex] = self.userFills
                        }
                        self.questions = newQuestions
                        if self.currentIndex >= self.questions.count {
                            self.currentIndex = max(0, self.questions.count - 1)
                        }
                        self.loadQuestionState()
                        if newQuestions.count > lastReportedCount {
                            lastReportedCount = newQuestions.count
                            Task { @MainActor in
                                self.generationSteps.append(GenerationStep(
                                    message: "Question \(newQuestions.count): Sentence with **\(newQuestions.count)** blank\(newQuestions.count == 1 ? "" : "s") ready...",
                                    icon: "text.insert"
                                ))
                            }
                        }
                    }
                }
            )
            if !questions.isEmpty {
                generationSteps.append(GenerationStep(
                    message: "All set! **\(questions.count)** fill-in-the-blank questions ready.",
                    icon: "checkmark.circle.fill"
                ))
            }
        } catch {
            print("[FillInTheBlanksViewModel] Generation failed: \(error)")
            generationError = "Could not generate fill-in-the-blank questions. Make sure Apple Intelligence is available and try again."
            generationSteps.append(GenerationStep(
                message: "Generation failed. Please try again.",
                icon: "exclamationmark.triangle.fill"
            ))
        }

        isGenerating = false
    }

    private func buildQuestion(from partial: GeneratedFillInBlank.PartiallyGenerated) -> FillInBlankQuestion? {
        introduceBlanksWithRestrictions(paragraph: partial.paragraph)
    }

    /// Allowed terms for manually carving blanks out of model-generated paragraphs.
    /// Sorted by length (longest first) so longer phrases are chosen before shorter ones. Uses Unicode subscripts (βₜ, ᾱₜ, ε).
    private static let blankableTerms: [String] = {
        let raw = [
            "classifier-free guidance", "reparameterization trick", "Denoising Diffusion Implicit Modeling",
            "forward process", "reverse process", "noise schedule", "latent space", "diffusion model architecture",
            "skip connections", "score function", "score matching", "denoising objective", "latent diffusion",
            "pixel space", "variance schedule", "Markov chain", "Stable Diffusion", "encoder - decoder",
            "cross-attention", "spatial attention", "residual block", "training image", "training images", "Gaussian noise",
            "bottleneck", "downsampling", "upsampling", "diffusion model", "conditioning",
            "U-Net", "VAE", "DDPM", "DDIM", "SDE", "EDM", "LDM",
            "diffusion", "Gaussian", "denoising", "timestep", "timesteps", "encoder", "decoder", "encoder-decoder",
            "attention", "sampling", "prior", "posterior", "ELBO", "likelihood", "training", "inference",
            "βₜ", "αₜ", "ᾱₜ", "ε", "σ", "xₜ", "epsilon", "sigma", "minimized",
            "latent", "embedding", "prediction", "schedule", "variance", "noise", "process"
        ]
        return raw.sorted(by: { $0.count > $1.count })
    }()

    /// Words we must never use as blanks (filler, too generic, or ambiguous).
    private static let doNotBlankTerms: Set<String> = [
        "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
        "of", "to", "in", "on", "at", "for", "with", "from", "by", "as",
        "and", "or", "but", "if", "so", "than", "that", "this", "these", "those",
        "it", "its", "they", "them", "we", "our", "you", "your", "he", "she",
        "have", "has", "had", "do", "does", "did", "can", "will", "would", "could",
        "each", "all", "some", "many", "more", "most", "other", "same", "such",
        "when", "where", "which", "who", "how", "what", "not", "no", "only", "just"
    ]

    /// Manually carve blanks out of a plain paragraph by replacing the first occurrences of restricted key terms with ___0___, ___1___, etc. (up to 6 blanks).
    /// Allowlist matching and excluded-word checks are case-insensitive.
    private func introduceBlanksWithRestrictions(paragraph: String?) -> FillInBlankQuestion? {
        guard let paragraph, !paragraph.isEmpty else { return nil }
        let terms = Self.blankableTerms
        let excludedLowercased = Set(Self.doNotBlankTerms.map { $0.lowercased() })
        var template = paragraph
        var answers: [String] = []
        let maxBlanks = 6

        while answers.count < maxBlanks {
            var chosen: (range: Range<String.Index>, term: String)?
            for term in terms {
                guard let range = template.range(of: term, options: .caseInsensitive) else { continue }
                let actualWord = String(template[range])
                if excludedLowercased.contains(actualWord.lowercased()) { continue }
                if answers.contains(where: { $0.caseInsensitiveCompare(actualWord) == .orderedSame }) { continue }
                chosen = (range, term)
                break
            }
            guard let (range, _) = chosen else { break }
            let actualWord = String(template[range])
            template.replaceSubrange(range, with: "___\(answers.count)___")
            answers.append(actualWord)
        }

        guard !answers.isEmpty else { return nil }
        return parseTemplateIntoQuestion(template: template, answers: answers)
    }

    /// Parse a template string with ___N___ markers into segments and a FillInBlankQuestion.
    private func parseTemplateIntoQuestion(template: String, answers: [String]) -> FillInBlankQuestion? {
        var segments: [FillInBlankSegment] = []
        var currentText = ""
        let chars = Array(template)
        let length = chars.count
        var i = 0

        func flushText() {
            if !currentText.isEmpty {
                segments.append(.text(currentText))
                currentText = ""
            }
        }

        while i < length {
            if i + 4 < length,
               chars[i] == "_", chars[i + 1] == "_", chars[i + 2] == "_" {
                var j = i + 3
                var indexString = ""
                while j < length, chars[j].isNumber {
                    indexString.append(chars[j])
                    j += 1
                }
                if !indexString.isEmpty,
                   j + 2 < length,
                   chars[j] == "_", chars[j + 1] == "_", chars[j + 2] == "_",
                   let blankIndex = Int(indexString),
                   blankIndex >= 0, blankIndex < answers.count {
                    flushText()
                    segments.append(.blank(blankIndex))
                    i = j + 3
                    continue
                }
            }
            currentText.append(chars[i])
            i += 1
        }

        flushText()
        guard !segments.isEmpty else { return nil }

        return FillInBlankQuestion(segments: segments, answers: answers)
    }
}
