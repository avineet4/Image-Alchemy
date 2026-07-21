import Foundation

struct HomeHelpSection: Identifiable, Equatable, Hashable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let keyPoints: [String]
}

extension HomeHelpSection {
    static let fullPipeline = HomeHelpSection(
        id: "fullPipeline",
        icon: "timeline.selection",
        title: "Full Pipeline",
        subtitle: "See diffusion as a story, not a formula.",
        description: "Scrub through the entire process from clean image → pure noise → reconstruction, watching how each step reshapes the latent space. Start here if you want the \"big picture\" first.",
        keyPoints: [
            "Visualise every stage of the forward and reverse diffusion process.",
            "Understand how noise schedules control the trade‑off between detail and stability.",
            "See how the latent space evolves instead of only looking at final images."
        ]
    )

    static let relatedMaths = HomeHelpSection(
        id: "maths",
        icon: "function",
        title: "Related Maths",
        subtitle: "Make the equations feel less scary.",
        description: "Connect visuals to the underlying probability, vectors, and loss curves. You'll meet concepts like noise schedules and dot products in small, focused scenes instead of a wall of symbols.",
        keyPoints: [
            "Link Gaussian noise, random variables, and expectations to what you see on screen.",
            "Build intuition for vectors, dot products, and similarity in latent space.",
            "Explore how loss functions guide the model toward sharper, more faithful reconstructions."
        ]
    )

    static let testKnowledge = HomeHelpSection(
        id: "knowledge",
        icon: "checkmark.circle",
        title: "Test Your Knowledge",
        subtitle: "Lock in what you've learned.",
        description: "Use quick questions and active recall to see what actually stuck. Great as a final pass after exploring the pipeline and maths, or whenever you want a fast refresher.",
        keyPoints: [
            "Mix of flashcards, quizzes, and matching so you're never just tapping through.",
            "Designed for short, focused sessions you can revisit as you learn more.",
            "Great checkpoint before explaining diffusion models to someone else."
        ]
    )

    static let all: [HomeHelpSection] = [
        .fullPipeline,
        .relatedMaths,
        .testKnowledge
    ]
}
