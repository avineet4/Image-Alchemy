import Foundation
import SwiftUI

// Represents a single step in the architecture overview (Phase 0).
struct ArchitectureOverviewStep: Identifiable {
    let id: Int
    let explanation: String
    
    let highlightForward: ArchitectureComponent?
    let highlightReverse: ReverseArchitectureComponent?
    
    var highlightedUnifiedComponents: Set<UnifiedArchitectureComponent> {
        var result = Set<UnifiedArchitectureComponent>()
        if let forward = highlightForward {
            result.insert(UnifiedArchitectureComponent.from(forward))
        }
        if let reverse = highlightReverse {
            result.insert(UnifiedArchitectureComponent.from(reverse))
        }
        return result
    }
    
    static let allSteps: [ArchitectureOverviewStep] = [
        ArchitectureOverviewStep(
            id: 0,
            explanation: "Diffusion models work in two phases: forward (add noise to an image) and reverse (remove noise to generate new images). The diagram shows the full pipeline.",
            highlightForward: nil,
            highlightReverse: nil
        ),
        ArchitectureOverviewStep(
            id: 1,
            explanation: "The original image x is our input in pixel space. This is the clean image before any processing.",
            highlightForward: .originalImage,
            highlightReverse: nil
        ),
        ArchitectureOverviewStep(
            id: 2,
            explanation: "The encoder ε compresses the image into a smaller latent representation. This makes diffusion computationally efficient.",
            highlightForward: .encoder,
            highlightReverse: nil
        ),
        ArchitectureOverviewStep(
            id: 3,
            explanation: "Latent space z is a compressed representation that preserves key features. Diffusion happens in this efficient space.",
            highlightForward: .latent,
            highlightReverse: nil
        ),
        ArchitectureOverviewStep(
            id: 4,
            explanation: "Forward diffusion adds Gaussian noise over many time steps according to a schedule. The image gradually becomes pure noise.",
            highlightForward: .diffusionProcess,
            highlightReverse: nil
        ),
        ArchitectureOverviewStep(
            id: 5,
            explanation: "After the forward process, we have noisy latent z_{t} - nearly pure Gaussian noise. This is the starting point for generation.",
            highlightForward: .noisyLatent,
            highlightReverse: nil
        ),
        ArchitectureOverviewStep(
            id: 6,
            explanation: "The text prompt is encoded by τ_{θ} into conditioning embeddings. These guide the model to generate images that match the prompt.",
            highlightForward: nil,
            highlightReverse: .conditioning
        ),
        ArchitectureOverviewStep(
            id: 7,
            explanation: "The U-Net is the neural network that predicts and removes noise. It uses cross-attention to the text embeddings to steer generation.",
            highlightForward: nil,
            highlightReverse: .unetDenoiser
        ),
        ArchitectureOverviewStep(
            id: 8,
            explanation: "After iterative denoising we get clean latent z. High-frequency details are restored in latent space.",
            highlightForward: nil,
            highlightReverse: .cleanLatent
        ),
        ArchitectureOverviewStep(
            id: 9,
            explanation: "The decoder D maps the clean latent back to pixel space, reconstructing the full-resolution image.",
            highlightForward: nil,
            highlightReverse: .decoder
        ),
        ArchitectureOverviewStep(
            id: 10,
            explanation: "The generated image x̃ is the final output. The reverse process has turned pure noise into a coherent image guided by the text prompt.",
            highlightForward: nil,
            highlightReverse: .generatedImage
        )
    ]
}
