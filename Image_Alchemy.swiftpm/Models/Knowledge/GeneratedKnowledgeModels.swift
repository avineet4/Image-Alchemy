import Foundation
import FoundationModels

// MARK: - Generable DTOs (Foundation Models)

@Generable
struct GeneratedFlashcard {
    @Guide(description: "A clear, descriptive term or question title for a flashcard about diffusion models. This can be a short phrase or full question, not just a single word.")
    let term: String

    @Guide(description: "Concise, student-friendly definition for the flashcard term.")
    let definition: String
}

@Generable
struct GeneratedQuizQuestion {
    @Guide(description: "A clear, single multiple-choice question about diffusion models, written for students.")
    let question: String

    @Guide(
        description: """
        Exactly four answer options. Each option must be a full answer phrase or sentence
        (for example, \"It gradually removes noise from an image to reconstruct it\"), not just a single
        letter like \"A\" or \"B\". Avoid labels such as \"Option A\" or \"All of the above\".
        """
    )
    let options: [String]

    @Guide(description: "The index (0-based) of the correct option in the options array.")
    let correctIndex: Int
}

@Generable
struct GeneratedMatchPair {
    @Guide(description: "Term or concept name, 1–4 words (e.g. \"Forward Process\", \"Epsilon prediction\").")
    let leftItem: String

    @Guide(description: "Single-sentence definition matching the left term; under 100 characters; end with a period.")
    let rightItem: String
}

@Generable
struct GeneratedFillInBlank {
    @Guide(
        description: """
        One short paragraph (exactly 2 sentences) about diffusion models. Plain English only-no markdown, no formatting, no blanks or placeholders; the app blanks key terms automatically. Cover concepts such as forward/reverse process, noise schedule, timesteps, U-Net, encoder-decoder, skip connections, attention, latent space, VAE, epsilon prediction, DDPM/DDIM, sampling, score matching, denoising, Markov chain, classifier-free guidance, guidance scale, text-to-image, latent diffusion, LoRA, inpainting. Example: "The forward diffusion process adds noise over many timesteps. A U-Net predicts the noise at each step so it can be removed."
        """
    )
    let paragraph: String
}
