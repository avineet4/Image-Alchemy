import SwiftUI

// Shared component model for the unified Stable Diffusion architecture diagram.
enum UnifiedArchitectureComponent: String, CaseIterable, Identifiable, Hashable {
    case originalImage
    case encoder
    case latent
    case diffusionProcess
    case noisyLatent
    case conditioning
    case unetDenoiser
    case cleanLatent
    case decoder
    case generatedImage
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .originalImage: return "Original Image"
        case .encoder: return "Encoder"
        case .latent: return "Latent"
        case .diffusionProcess: return "Diffusion Process"
        case .noisyLatent: return "Noisy Latent"
        case .conditioning: return "Conditioning"
        case .unetDenoiser: return "U‑Net Denoiser"
        case .cleanLatent: return "Clean Latent"
        case .decoder: return "Decoder"
        case .generatedImage: return "Generated Image"
        }
    }
    
    enum Region {
        case pixelSpace
        case latentSpace
        case conditioning
    }
    
    var region: Region {
        switch self {
        case .originalImage, .encoder, .decoder, .generatedImage:
            return .pixelSpace
        case .latent, .diffusionProcess, .noisyLatent, .unetDenoiser, .cleanLatent:
            return .latentSpace
        case .conditioning:
            return .conditioning
        }
    }
    
    var color: Color {
        switch region {
        case .pixelSpace:
            return .pink
        case .latentSpace:
            return .green
        case .conditioning:
            return .orange
        }
    }
    
    static func from(_ component: ArchitectureComponent) -> UnifiedArchitectureComponent {
        switch component {
        case .originalImage: return .originalImage
        case .encoder: return .encoder
        case .latent: return .latent
        case .diffusionProcess: return .diffusionProcess
        case .noisyLatent: return .noisyLatent
        }
    }
    
    static func from(_ component: ReverseArchitectureComponent) -> UnifiedArchitectureComponent {
        switch component {
        case .noisyLatent: return .noisyLatent
        case .conditioning: return .conditioning
        case .unetDenoiser: return .unetDenoiser
        case .cleanLatent: return .cleanLatent
        case .decoder: return .decoder
        case .generatedImage: return .generatedImage
        }
    }
}

enum DiffusionFlowDirection {
    case neutral
    case forward
    case reverse
}
