import Foundation

// A single quiz question with multiple choice options
struct QuizQuestion: Identifiable {
    let id: UUID
    let question: String
    let options: [String]
    let correctIndex: Int
    
    init(id: UUID = UUID(), question: String, options: [String], correctIndex: Int) {
        self.id = id
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
    }
}

// MARK: - Static Sample Data

extension QuizQuestion {
    static let sampleQuestions: [QuizQuestion] = [
        QuizQuestion(
            question: "What does the forward process do in a diffusion model?",
            options: [
                "Removes noise from images",
                "Adds Gaussian noise to images over time",
                "Compresses images to latent space",
                "Predicts the next image in a sequence"
            ],
            correctIndex: 1
        ),
        QuizQuestion(
            question: "What does the U-Net predict at each denoising step?",
            options: [
                "The final clean image",
                "The noise ε added to the image",
                "The timestep t",
                "The latent representation"
            ],
            correctIndex: 1
        ),
        QuizQuestion(
            question: "What does t = T represent in the diffusion process?",
            options: [
                "Clean image with no noise",
                "Maximum noise (pure random)",
                "Halfway through the process",
                "The latent space"
            ],
            correctIndex: 1
        ),
        QuizQuestion(
            question: "What is latent space diffusion?",
            options: [
                "Diffusion in pixel space only",
                "Operating on compressed representations (e.g., from VAE)",
                "A type of noise schedule",
                "The forward process equation"
            ],
            correctIndex: 1
        ),
        QuizQuestion(
            question: "What does the noise schedule βₜ control?",
            options: [
                "The number of timesteps",
                "How much noise is added at each step t",
                "The U-Net architecture",
                "The loss function"
            ],
            correctIndex: 1
        ),
    ]
}
