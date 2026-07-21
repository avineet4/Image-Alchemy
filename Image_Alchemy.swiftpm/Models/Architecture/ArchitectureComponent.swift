import SwiftUI

// Represents the different components in the diffusion architecture diagram
enum ArchitectureComponent: String, CaseIterable, Identifiable {
    case originalImage
    case encoder
    case latent
    case diffusionProcess
    case noisyLatent
    
    var id: String { rawValue }
    
    // Display label for the component
    var label: String {
        switch self {
        case .originalImage:
            return "Image"
        case .encoder:
            return "ε"
        case .latent:
            return "z"
        case .diffusionProcess:
            return "Diffusion"
        case .noisyLatent:
            return "z_{t}"
        }
    }
    
    // Subtitle description for the component
    var subtitle: String {
        switch self {
        case .originalImage:
            return "Image"
        case .encoder:
            return "Encoder"
        case .latent:
            return "Latent"
        case .diffusionProcess:
            return "Add Noise"
        case .noisyLatent:
            return "Noisy"
        }
    }
    
    // Color associated with the component
    var color: Color {
        switch self {
        case .originalImage, .encoder:
            return .pink
        case .latent, .diffusionProcess, .noisyLatent:
            return .green
        }
    }
    
    // Whether this component belongs to Pixel Space (vs Latent Space)
    var isPixelSpace: Bool {
        switch self {
        case .originalImage, .encoder:
            return true
        case .latent, .diffusionProcess, .noisyLatent:
            return false
        }
    }
}
