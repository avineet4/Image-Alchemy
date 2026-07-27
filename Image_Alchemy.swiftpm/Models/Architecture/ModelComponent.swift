import Foundation

// MARK: - ModelComponent

// Pipeline component identifier with human-readable description; bridges ArchitectureComponent and ReverseArchitectureComponent to UI.
enum ModelComponent: String {
    case whatIsDiffusion = "What is a Diffusion Model?"
    case originalImage = "Original Image"
    case encoder = "Encoder"
    case latent = "Latent"
    case diffusionProcess = "Forward Diffusion Process"
    case noisyLatent = "Noisy Latent"
    case conditioning = "Conditioning"
    case unetDenoiser = "U-Net Denoiser"
    case cleanLatent = "Clean Latent"
    case decoder = "Variable Autoencoder (VAE) Decoder"
    case generatedImage = "Generated Image"

    case none = ""

    var description: String {
        switch self {
        case .whatIsDiffusion:
            return "Diffusion models are a class of generative AI models that create images by learning to reverse a gradual noise-adding process. They work in two phases: forward diffusion (adding noise) and reverse diffusion (removing noise to generate new images)."
        case .originalImage:
            return "The original image x is our input in pixel space. This is the clean image before any processing."
        case .encoder:
            return "The encoder ε compresses the image into a smaller latent representation. This makes diffusion computationally efficient."
        case .latent:
            return "Latent space z is a compressed representation that preserves key features. Diffusion happens in this efficient space."
        case .diffusionProcess:
            return "Forward diffusion adds Gaussian noise over many time steps according to a schedule. The image gradually becomes pure noise."
        case .noisyLatent:
            return "After the forward process, we have noisy latent z_{t} - nearly pure Gaussian noise. This is the starting point for generation."
        case .conditioning:
            return "The text prompt is encoded by τ_{θ} into conditioning embeddings. These guide the model to generate images that match the prompt."
        case .unetDenoiser:
            return "The U-Net is the neural network that predicts and removes noise. It uses cross-attention to the text embeddings to steer generation."
        case .cleanLatent:
            return "After iterative denoising we get clean latent z. High-frequency details are restored in latent space."
        case .decoder:
            return "The decoder D maps the clean latent back to pixel space, reconstructing the full-resolution image."
        case .generatedImage:
            return "The generated image x̃ is the final output. The reverse process has turned pure noise into a coherent image guided by the text prompt."
        case .none:
            return ""
        }
    }

    init(_ component: UnifiedArchitectureComponent) {
        switch component {
        case .originalImage: self = .originalImage
        case .encoder: self = .encoder
        case .latent: self = .latent
        case .diffusionProcess: self = .diffusionProcess
        case .noisyLatent: self = .noisyLatent
        case .conditioning: self = .conditioning
        case .unetDenoiser: self = .unetDenoiser
        case .cleanLatent: self = .cleanLatent
        case .decoder: self = .decoder
        case .generatedImage: self = .generatedImage
        }
    }
}

// MARK: - Sheet modes

// Content mode for the bottom sheet when on the Latent Space lab.
enum LatentLabSheetMode {
    case vaeOverview
    case trainingDataEncoder
    case latentGrid
}

// Content mode for the Conditioning & Guidance lab bottom sheet (tapped area).
enum ConditioningLabSheetMode {
    case overview
    case embeddings
    case noisyLatent
    case unet
    case noisePrediction
}
