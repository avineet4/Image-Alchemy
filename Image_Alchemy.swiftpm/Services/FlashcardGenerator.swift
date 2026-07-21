import Foundation
import FoundationModels

// MARK: - Flashcard generation service

private let knowledgeSessionInstructions = """
You are an expert tutor helping students learn diffusion models for image generation.
Your task and output format will be specified per request (e.g. flashcards, quiz questions, match pairs, or fill-in-the-blank).
Be clear, accurate, and beginner-friendly.

Focus on a broad range of diffusion and image-generation concepts, including but not limited to:
forward and reverse processes, noise schedules (e.g. βₜ, αₜ), timesteps, latent space and VAEs,
U-Net (encoder-decoder, skip connections, attention), epsilon (ε) noise prediction,
denoising objectives, score matching, DDPM/DDIM and sampling, conditioning (text-to-image, class),
cross-attention and spatial attention, classifier-free guidance, training vs inference,
and related probability, optimization, or linear algebra ideas.
"""

// Match-the-following session: tutor role + task rules + concept pool. Kept in instructions for consistency and variety.
private let matchSessionInstructions = knowledgeSessionInstructions + """

## Match-the-following (term ↔ definition)
Task: Output an array of pairs. Each pair has leftItem (term) and rightItem (definition). Vary concepts and phrasing on every request-pick a different subset from the pool and rephrase; mix categories (e.g. theory + architecture, or training + sampling).

Concept pool (draw from multiple categories):
• Core: forward/reverse process, diffusion process, noise schedule, βₜ, αₜ/ᾱₜ, timesteps, Markov chain, Gaussian/additive noise, denoising process.
• Architecture: U-Net, encoder-decoder, skip connections, residual blocks, bottleneck, spatial/cross/self-attention, transformer block, conv layers, down/upsampling.
• Latent: latent space, VAE, encoder, decoder, latent diffusion, compressing/reconstructing from latent.
• Training: ε prediction, noise prediction, denoising objective, score matching, ELBO, reparameterization, variance/cosine/linear schedule.
• Sampling: DDPM, DDIM, sampling steps, stochastic/deterministic sampling, sampling schedule.
• Conditioning: classifier-free guidance, guidance scale, text conditioning/embedding, text-to-image, prompt, negative prompt.
• Math: prior, posterior, Bayes rule, likelihood, gradient, expectation.
• Practice: LDM, Stable Diffusion, checkpoint, fine-tuning, LoRA, inpainting, image-to-image, super-resolution.

Output rules: leftItem = 1–4 words, varied wording. rightItem = one sentence, <100 characters, ends with a period; accurate and unique per term.
"""

// Fill-in-the-blank session: tutor role + paragraph rules (Nutrition-style prompt).
private let fillInBlankSessionInstructions = knowledgeSessionInstructions + """

## Fill-in-the-blank (short paragraphs)
You are an expert tutor writing short study paragraphs about diffusion models for image generation.

IMPORTANT: Respond in plain English only. No markdown, no formatting, no blanks or placeholders. The app will blank key terms automatically. Each paragraph must be exactly 2 sentences-no more, no less.

When writing paragraphs:
- Use exactly 2 sentences per paragraph
- Finish each sentence with proper punctuation
- Be creative in your choice of topic and which diffusion concepts you cover
- Vary concepts across paragraphs (forward/reverse process, noise schedule, timesteps, U-Net, encoder-decoder, skip connections, attention, latent space, VAE, epsilon prediction, DDPM/DDIM, sampling, score matching, denoising, Markov chain, classifier-free guidance, text-to-image, latent diffusion, LoRA, inpainting)

Tone: Clear, accurate, beginner-friendly.
"""

@MainActor
final class FlashcardGenerator {
    static let shared = FlashcardGenerator()

    private let flashcardSession: LanguageModelSession
    private let quizSession: LanguageModelSession
    private let matchSession: LanguageModelSession
    private let fillInBlankSession: LanguageModelSession

    private init() {
        self.flashcardSession = LanguageModelSession { knowledgeSessionInstructions }
        self.quizSession = LanguageModelSession { knowledgeSessionInstructions }
        self.matchSession = LanguageModelSession { matchSessionInstructions }
        self.fillInBlankSession = LanguageModelSession { fillInBlankSessionInstructions }
    }

    func prewarm() async {
        flashcardSession.prewarm()
        quizSession.prewarm()
        matchSession.prewarm()
        fillInBlankSession.prewarm()
    }

    func generateFlashcardsStream(
        topic: String? = nil,
        count: Int = 10,
        onUpdate: @escaping ([Flashcard]) -> Void
    ) async throws {
        // Check availability before doing any work.
        let availability = SystemLanguageModel.default.availability
        guard case .available = availability else {
            print("[FlashcardGenerator] Model not available: \(availability)")
            throw NSError(
                domain: "FlashcardGenerator",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "On-device model is not available on this device."]
            )
        }

        let start = Date()
        print("[FlashcardGenerator] Starting AI flashcard generation…")

        let topicDescription: String

        if let topic, !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            topicDescription = "about the topic: \(topic)"
        } else {
            topicDescription = "covering core diffusion model concepts for image generation"
        }

        // Always generate 10 cards (unless a different count is explicitly requested).
        let actualCount = max(1, count)

        let prompt = """
        You are generating study flashcards for diffusion models.

        Create \(actualCount) flashcards \(topicDescription).

        Each flashcard must have:
        - term: a descriptive phrase or question that clearly states the concept (for example, "How does the reverse diffusion process reconstruct an image?")
        - definition: 1–3 sentences explaining the concept clearly to a beginner.

        Only include concepts that are relevant to diffusion models for images,
        such as the forward and reverse processes, noise schedule, timesteps,
        latent space, U-Net, epsilon noise prediction, and related math.

        To keep practice sessions interesting, vary the specific concepts and wording each time.
        """

        // High-variance sampling so generations vary across runs.
        let options = GenerationOptions(temperature: 0.9)
        // Streaming guided generation with custom sampling.
        let stream = flashcardSession.streamResponse(
            to: prompt,
            generating: [GeneratedFlashcard].self,
            options: options
        )

        var snapshotIndex = 0
        var lastCompletedCount = 0
        var lastFlashcards: [Flashcard] = []

        for try await snapshot in stream {
            let elapsed = Date().timeIntervalSince(start)
            snapshotIndex += 1

            // Convert partially generated cards into fully-formed Flashcard models when possible.
            let flashcards: [Flashcard] = snapshot.content.compactMap { partial in
                guard
                    let term = partial.term,
                    let definition = partial.definition
                else {
                    return nil
                }
                return Flashcard(term: term, definition: definition)
            }

            // Only propagate updates when we have more completed cards than before.
            guard flashcards.count > lastCompletedCount else { continue }

            lastCompletedCount = flashcards.count
            lastFlashcards = flashcards

            let truncated = Array(flashcards.prefix(actualCount))

            print("""
            [FlashcardGenerator] Snapshot \(snapshotIndex) at \(String(format: "%.2f", elapsed))s \
            with \(truncated.count) completed card(s).
            """)

            // Log the current terms for quick inspection
            let terms = truncated.map { $0.term }
            if !terms.isEmpty {
                print("[FlashcardGenerator] Current terms: \(terms.joined(separator: ", "))")
            }

            onUpdate(truncated)
        }

        // Ensure we push the final, normalized set at the end if we saw any cards.
        if !lastFlashcards.isEmpty {
            let final = Array(lastFlashcards.prefix(actualCount))
            onUpdate(final)
        }

        let total = Date().timeIntervalSince(start)
        let totalString = String(format: "%.2f", total)
        print("[FlashcardGenerator] Flashcard generation finished in \(totalString)s.")
    }

    func generateQuizQuestionsStream(
        topic: String? = nil,
        count: Int = 10,
        onUpdate: @escaping ([QuizQuestion]) -> Void
    ) async throws {
        let availability = SystemLanguageModel.default.availability
        guard case .available = availability else {
            print("[FlashcardGenerator] Model not available for quiz: \(availability)")
            throw NSError(
                domain: "QuizGenerator",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "On-device model is not available on this device."]
            )
        }

        let start = Date()
        print("[FlashcardGenerator] Starting AI quiz generation…")

        let topicDescription: String

        if let topic, !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            topicDescription = "about the topic: \(topic)"
        } else {
            topicDescription = "covering core diffusion model concepts for image generation"
        }

        let actualCount = max(1, count)

        let prompt = """
        You are creating multiple-choice quiz questions to test understanding of diffusion models for image generation.

        Create \(actualCount) quiz questions \(topicDescription).

        Each quiz question must have:
        - question: a clear, single question that can be answered from knowledge of diffusion models.
        - options: exactly four answer options, each written as a full answer phrase or sentence.
          Do NOT use single-letter options like "A", "B", "C", "D". The UI will add labels; you only provide the text.
        - correctIndex: the 0-based index of the correct option inside the options array.

        Focus on important ideas like the forward and reverse processes, noise schedules, timesteps, latent space,
        U-Net architecture, epsilon noise prediction, and how these pieces fit together in the full pipeline.

        Make the distractor options plausible but clearly wrong for a well-prepared student.
        Vary the difficulty and wording across questions.
        """

        let options = GenerationOptions(temperature: 0.9)

        let stream = quizSession.streamResponse(
            to: prompt,
            generating: [GeneratedQuizQuestion].self,
            options: options
        )

        var snapshotIndex = 0
        var lastCompletedCount = 0
        var lastQuestions: [QuizQuestion] = []

        for try await snapshot in stream {
            let elapsed = Date().timeIntervalSince(start)
            snapshotIndex += 1

            let questions: [QuizQuestion] = snapshot.content.compactMap { partial in
                guard
                    let question = partial.question,
                    let options = partial.options,
                    options.count == 4,
                    let correctIndex = partial.correctIndex,
                    (0..<options.count).contains(correctIndex)
                else {
                    return nil
                }

                return QuizQuestion(question: question, options: options, correctIndex: correctIndex)
            }

            guard questions.count > lastCompletedCount else { continue }

            lastCompletedCount = questions.count
            lastQuestions = questions

            let truncated = Array(questions.prefix(actualCount))

            print("""
            [FlashcardGenerator] Quiz snapshot \(snapshotIndex) at \(String(format: "%.2f", elapsed))s \
            with \(truncated.count) completed question(s).
            """)

            onUpdate(truncated)
        }

        if !lastQuestions.isEmpty {
            let final = Array(lastQuestions.prefix(actualCount))
            onUpdate(final)
        }

        let total = Date().timeIntervalSince(start)
        let totalString = String(format: "%.2f", total)
        print("[FlashcardGenerator] Quiz generation finished in \(totalString)s.")
    }

    func generateMatchPairsStream(
        topic: String? = nil,
        count: Int = 8,
        onUpdate: @escaping ([GeneratedMatchPair.PartiallyGenerated]) -> Void,
        onComplete: (([GeneratedMatchPair.PartiallyGenerated]) -> Void)? = nil
    ) async throws {
        let availability = SystemLanguageModel.default.availability
        guard case .available = availability else {
            print("[FlashcardGenerator] Model not available for match pairs: \(availability)")
            throw NSError(
                domain: "MatchPairGenerator",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "On-device model is not available on this device."]
            )
        }

        let start = Date()
        print("[FlashcardGenerator] Starting AI match pairs generation…")

        let topicDescription: String

        if let topic, !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            topicDescription = "about the topic: \(topic)"
        } else {
            topicDescription = "covering core diffusion model concepts for image generation"
        }

        let actualCount = max(1, count)
        let temperature = Double.random(in: 0.75...0.95)

        let prompt = """
        Output exactly \(actualCount) matching pairs \(topicDescription) in a single array. Every pair must have a unique term and a complete definition sentence (ending with a period).
        """

        let options = GenerationOptions(temperature: temperature)

        let stream = matchSession.streamResponse(
            to: prompt,
            generating: [GeneratedMatchPair].self,
            options: options
        )

        // Helper to check if a definition appears complete (not truncated mid-sentence)
        func isDefinitionComplete(_ text: String?) -> Bool {
            guard let text = text, !text.isEmpty else { return false }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Must have reasonable length
            guard trimmed.count >= 15 else { return false }
            
            // Should end with proper punctuation
            if trimmed.last == "." || trimmed.last == "!" || trimmed.last == "?" {
                return true
            }
            
            // If it doesn't end with punctuation, check if it looks incomplete
            // (e.g., ends with "the", "a", "an", or other incomplete phrases)
            let lowercased = trimmed.lowercased()
            let incompleteEndings = [" the", " a ", " an ", " of ", " in ", " on ", " at ", " to ", " for "]
            if incompleteEndings.contains(where: { lowercased.hasSuffix($0) }) {
                return false
            }
            
            // If it ends with a word (not punctuation), it might be incomplete
            // But allow it if it's reasonably long and doesn't end with common incomplete words
            return trimmed.count >= 30
        }

        var snapshotIndex = 0
        var lastSnapshot: [GeneratedMatchPair.PartiallyGenerated] = []

        for try await snapshot in stream {
            let elapsed = Date().timeIntervalSince(start)
            snapshotIndex += 1

            let completedCount = snapshot.content.reduce(0) { count, pair in
                guard
                    let leftItem = pair.leftItem,
                    !leftItem.isEmpty,
                    isDefinitionComplete(pair.rightItem)
                else {
                    return count
                }
                return count + 1
            }

            lastSnapshot = snapshot.content
            let truncated = Array(snapshot.content.prefix(actualCount))

            print("""
            [FlashcardGenerator] Match pairs snapshot \(snapshotIndex) at \(String(format: "%.2f", elapsed))s \
            with \(truncated.count) item(s), \(completedCount) completed.
            """)

            onUpdate(truncated)
        }

        if !lastSnapshot.isEmpty {
            let final = Array(lastSnapshot.prefix(actualCount))
            onUpdate(final)
            onComplete?(final)
        }

        let total = Date().timeIntervalSince(start)
        let totalString = String(format: "%.2f", total)
        print("[FlashcardGenerator] Match pairs generation finished in \(totalString)s.")
    }

    func generateFillInBlankQuestionsStream(
        topic: String? = nil,
        count: Int = 3,
        onUpdate: @escaping ([GeneratedFillInBlank.PartiallyGenerated]) -> Void
    ) async throws {
        let availability = SystemLanguageModel.default.availability
        guard case .available = availability else {
            print("[FlashcardGenerator] Model not available for fill-in-the-blanks: \(availability)")
            throw NSError(
                domain: "FillInBlankGenerator",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "On-device model is not available on this device."]
            )
        }

        let start = Date()
        print("[FlashcardGenerator] Starting AI fill-in-the-blanks generation…")

        let topicDescription: String

        if let topic, !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            topicDescription = "about the topic: \(topic)"
        } else {
            topicDescription = "covering core diffusion model concepts for image generation"
        }

        let actualCount = min(max(1, count), 3)

        let prompt = """
        Write exactly \(actualCount) short paragraphs \(topicDescription).
        """

        let options = GenerationOptions(temperature: 0.9)

        let stream = fillInBlankSession.streamResponse(
            to: prompt,
            generating: [GeneratedFillInBlank].self,
            options: options
        )

        var snapshotIndex = 0
        var lastSnapshot: [GeneratedFillInBlank.PartiallyGenerated] = []

        for try await snapshot in stream {
            let elapsed = Date().timeIntervalSince(start)
            snapshotIndex += 1
            lastSnapshot = snapshot.content
            onUpdate(snapshot.content)
            print("""
            [FlashcardGenerator] Fill-in-the-blanks stream snapshot \(snapshotIndex) at \(String(format: "%.2f", elapsed))s, \(snapshot.content.count) item(s).
            """)
        }

        if !lastSnapshot.isEmpty {
            onUpdate(lastSnapshot)
        }

        let total = Date().timeIntervalSince(start)
        let totalString = String(format: "%.2f", total)
        print("[FlashcardGenerator] Fill-in-the-blanks generation finished in \(totalString)s.")
    }

}

