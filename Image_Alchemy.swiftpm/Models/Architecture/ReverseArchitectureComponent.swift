import SwiftUI

// Represents the different components in the reverse diffusion architecture diagram
enum ReverseArchitectureComponent: String, CaseIterable, Identifiable {
    case noisyLatent
    case conditioning
    case unetDenoiser
    case cleanLatent
    case decoder
    case generatedImage
    
    var id: String { rawValue }
    
    // Display label for the component
    var label: String {
        switch self {
        case .noisyLatent:
            return "z_{t}"
        case .conditioning:
            return "τ_{θ}"
        case .unetDenoiser:
            return "U-Net"
        case .cleanLatent:
            return "z"
        case .decoder:
            return "D"
        case .generatedImage:
            return "Image"
        }
    }
    
    // Subtitle description for the component
    var subtitle: String {
        switch self {
        case .noisyLatent:
            return "Noisy"
        case .conditioning:
            return "Encoder"
        case .unetDenoiser:
            return "Denoiser"
        case .cleanLatent:
            return "Clean"
        case .decoder:
            return "Decoder"
        case .generatedImage:
            return "Generated"
        }
    }
    
    // Color associated with the component
    var color: Color {
        switch self {
        case .noisyLatent, .unetDenoiser, .cleanLatent:
            return .green
        case .conditioning:
            return .orange
        case .decoder, .generatedImage:
            return .pink
        }
    }
    
    // Which space this component belongs to
    var space: String {
        switch self {
        case .noisyLatent, .unetDenoiser, .cleanLatent:
            return "Latent Space"
        case .conditioning:
            return "Conditioning"
        case .decoder, .generatedImage:
            return "Pixel Space"
        }
    }
}
