import Foundation

// A single flashcard with a term and its definition
struct Flashcard: Identifiable {
    let id: UUID
    let term: String
    let definition: String
    
    init(id: UUID = UUID(), term: String, definition: String) {
        self.id = id
        self.term = term
        self.definition = definition
    }
}

// MARK: - Static Sample Data

extension Flashcard {
    // Sample flashcards for diffusion model concepts
    static let sampleFlashcards: [Flashcard] = [
        Flashcard(
            term: "Diffusion",
            definition: "A generative process that gradually adds noise to data, then learns to reverse it to create new samples."
        ),
        Flashcard(
            term: "Forward Process",
            definition: "The step-by-step addition of Gaussian noise to an image over T timesteps, transforming it into pure noise."
        ),
        Flashcard(
            term: "Reverse Process",
            definition: "The learned denoising process that removes noise step by step to generate a clean image from random noise."
        ),
        Flashcard(
            term: "Noise Schedule (βₜ)",
            definition: "A schedule that determines how much noise is added at each timestep t. Typically increases over time."
        ),
        Flashcard(
            term: "U-Net",
            definition: "A neural network architecture with encoder-decoder structure and skip connections, used to predict noise at each denoising step."
        ),
        Flashcard(
            term: "Timestep",
            definition: "A discrete step in the diffusion process. At t=0 the image is clean; at t=T it is pure noise."
        ),
        Flashcard(
            term: "Latent Space",
            definition: "A compressed representation of data (e.g., from a VAE). Latent diffusion models operate here for efficiency."
        ),
        Flashcard(
            term: "ε (epsilon)",
            definition: "The noise term. The model learns to predict ε at each timestep so it can be subtracted to denoise."
        ),
    ]
}
