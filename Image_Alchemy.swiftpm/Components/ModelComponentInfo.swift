import SwiftUI

// MARK: - ExpandableBottomSheet

struct ExpandableBottomSheet: View {
    @Binding var selectedComponent: ModelComponent
    @Binding var isExpanded: Bool
    var showVAEContent: Bool = false
    var latentLabSheetMode: LatentLabSheetMode? = nil
    var showReverseDiffusionContent: Bool = false
    var showConditioningContent: Bool = false
    var conditioningLabSheetMode: ConditioningLabSheetMode? = nil

    init(selectedComponent: Binding<ModelComponent>, isExpanded: Binding<Bool>, showVAEContent: Bool = false, latentLabSheetMode: LatentLabSheetMode? = nil, showReverseDiffusionContent: Bool = false, showConditioningContent: Bool = false, conditioningLabSheetMode: ConditioningLabSheetMode? = nil) {
        self._selectedComponent = selectedComponent
        self._isExpanded = isExpanded
        self.showVAEContent = showVAEContent
        self.latentLabSheetMode = latentLabSheetMode
        self.showReverseDiffusionContent = showReverseDiffusionContent
        self.showConditioningContent = showConditioningContent
        self.conditioningLabSheetMode = conditioningLabSheetMode
    }
    
    private var vaeTitle: String {
        guard showVAEContent, let mode = latentLabSheetMode else { return "Variable Autoencoder (VAE)" }
        switch mode {
        case .vaeOverview: return "Variable Autoencoder (VAE)"
        case .trainingDataEncoder: return "Training Data"
        case .latentGrid: return "Latent Grid"
        }
    }
    
    private var vaeBriefDescription: String {
        let mode = latentLabSheetMode ?? .vaeOverview
        switch mode {
        case .vaeOverview: return VAEExplanation.briefDescription
        case .trainingDataEncoder: return VAEExplanation.trainingDataEncoderBrief
        case .latentGrid: return VAEExplanation.latentGridBrief
        }
    }
    
    @ViewBuilder
    private var vaeExpandedContent: some View {
        let mode = latentLabSheetMode ?? .vaeOverview
        switch mode {
        case .vaeOverview: VAEExplanationView()
        case .trainingDataEncoder: VAETrainingDataEncoderExplanationView()
        case .latentGrid: VAELatentGridExplanationView()
        }
    }
    
    private static let reverseDiffusionBrief = "The reverse diffusion process iteratively removes noise from a noisy latent. Starting from pure noise (e.g. x₁₀), the U-Net predicts and subtracts noise at each step until a clean image emerges."

    private static let conditioningBrief = "Text is tokenized and encoded into embeddings, then injected into the U-Net via cross-attention. The U-Net uses the noisy latent and these embeddings to predict noise, guiding generation to match the prompt."

    private var conditioningTitle: String {
        switch conditioningLabSheetMode ?? .overview {
        case .overview: return "Conditioning & Guidance"
        case .embeddings: return "Embeddings"
        case .noisyLatent: return "Noisy latent zₜ"
        case .unet: return "U-Net"
        case .noisePrediction: return "Noise prediction εᶿ"
        }
    }

    private var conditioningBriefDescription: String {
        switch conditioningLabSheetMode ?? .overview {
        case .overview: return Self.conditioningBrief
        case .embeddings: return "The text prompt is tokenized and encoded into dense vectors (embeddings). These are fed into the U-Net via cross-attention to guide generation."
        case .noisyLatent: return "Noisy latent zₜ is the starting point for denoising. It is nearly pure Gaussian noise; the U-Net iteratively predicts and removes noise to reveal the image."
        case .unet: return "The U-Net has a U-shaped encoder-decoder. It takes the noisy latent and text embeddings, and uses cross-attention to predict the noise to remove at each denoising step."
        case .noisePrediction: return "The U-Net outputs a noise prediction εᶿ with the same shape as the latent. This prediction is used in the sampling step to update zₜ toward a cleaner latent at each denoising step."
        }
    }

    @ViewBuilder
    private var conditioningExpandedContent: some View {
        switch conditioningLabSheetMode ?? .overview {
        case .overview, .embeddings: ConditioningExplanation()
        case .noisyLatent: NoisyLatentExplanation()
        case .unet, .noisePrediction: UNetDenoiserExplanation()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showVAEContent || showReverseDiffusionContent || showConditioningContent || selectedComponent != .none {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(showVAEContent ? vaeTitle : (showReverseDiffusionContent ? "Reverse Diffusion Process" : (showConditioningContent ? conditioningTitle : selectedComponent.rawValue)))
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Show Less" : "Learn More")
                                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            }
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.indigo, in: .rect(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !isExpanded {
                        if showVAEContent {
                            Text(vaeBriefDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else if showReverseDiffusionContent {
                            Text(Self.reverseDiffusionBrief)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else if showConditioningContent {
                            Text(conditioningBriefDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else {
                            RichText(text: selectedComponent.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    if isExpanded {
                        ScrollView {
                            if showVAEContent {
                                vaeExpandedContent
                            } else if showReverseDiffusionContent {
                                ReverseDiffusionExplanationView()
                            } else if showConditioningContent {
                                conditioningExpandedContent
                            } else {
                                DetailedExplanation(component: selectedComponent)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(
            maxWidth: isExpanded ? 600 : 400
        )
        .frame(
            maxHeight: isExpanded ? 420 : 160,
            alignment: .top
        )
        .containerShape(.rect(cornerRadius: 24))
        .glassEffect(.regular, in: .rect(corners: .concentric(minimum: 24), isUniform: true))
    }
}

// MARK: - DetailedExplanation

struct DetailedExplanation: View {
    let component: ModelComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch component {
            case .whatIsDiffusion:
                WhatIsDiffusionExplanation()
            case .originalImage, .encoder, .latent, .diffusionProcess, .noisyLatent, .conditioning, .unetDenoiser, .cleanLatent, .decoder, .generatedImage:
                DiffusionComponentExplanation(component: component)
            case .none:
                Text("")
            }
        }
    }
}

// MARK: - Diffusion Component Explanation

struct DiffusionComponentExplanation: View {
    let component: ModelComponent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            switch component {
            case .originalImage:
                OriginalImageExplanation()
            case .encoder:
                EncoderExplanation()
            case .latent:
                LatentExplanation()
            case .diffusionProcess:
                DiffusionProcessExplanation()
            case .noisyLatent:
                NoisyLatentExplanation()
            case .conditioning:
                ConditioningExplanation()
            case .unetDenoiser:
                UNetDenoiserExplanation()
            case .cleanLatent:
                CleanLatentExplanation()
            case .decoder:
                DecoderExplanation()
            case .generatedImage:
                GeneratedImageExplanation()
            case .whatIsDiffusion, .none:
                EmptyView()
            }
        }
    }
}

// MARK: - Detailed Diffusion Component Explanations

struct OriginalImageExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The original image x₀ is our input in pixel space. This is the clean image before any processing begins.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "photo.fill",
                    title: "Pixel Space",
                    text: "Images start as high-resolution pixel arrays (e.g., 512×512 or 1024×1024 pixels). Each pixel contains RGB color values, making pixel space very high-dimensional."
                )
                
                ExplanationItem(
                    icon: "arrow.right.circle.fill",
                    title: "Starting Point",
                    text: "This clean image serves as the starting point for the forward diffusion process. It will be gradually corrupted with noise to train the model."
                )
            }
        }
    }
}

struct EncoderExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The encoder ε (epsilon) compresses the image into a smaller latent representation. This makes diffusion computationally efficient.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "arrow.down.circle.fill",
                    title: "Compression",
                    text: "The encoder uses a convolutional neural network to reduce image dimensions. For example, a 512×512 image might be compressed to 64×64 in latent space, reducing computation by 64×."
                )
                
                ExplanationItem(
                    icon: "brain.head.profile",
                    title: "Feature Preservation",
                    text: "Despite compression, the encoder preserves essential visual features like shapes, textures, and semantic content. The latent representation captures what matters for image generation."
                )
                
                ExplanationItem(
                    icon: "speedometer",
                    title: "Efficiency",
                    text: "By operating in latent space instead of pixel space, diffusion models can generate images much faster while maintaining high quality."
                )
            }
        }
    }
}

struct LatentExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Latent space z is a compressed representation that preserves key features. Diffusion happens in this efficient space.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "cube.fill",
                    title: "Compressed Representation",
                    text: "Latent space is a lower-dimensional space where images are represented more efficiently. Instead of millions of pixels, we work with thousands of latent values."
                )
                
                ExplanationItem(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Diffusion Operations",
                    text: "All noise addition and removal operations happen in latent space. This includes forward diffusion (adding noise) and reverse diffusion (removing noise)."
                )
                
                ExplanationItem(
                    icon: "eye.fill",
                    title: "Feature Rich",
                    text: "Despite being compressed, latent representations contain rich semantic information. The model learns to manipulate these features to generate diverse, high-quality images."
                )
            }
        }
    }
}

struct DiffusionProcessExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RichText(text: "The forward diffusion process gradually corrupts a clean example with Gaussian noise over many time steps, until it becomes almost pure noise.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "waveform.path",
                    title: "Noise schedule",
                    text: "A predefined schedule βₜ controls how much noise is added at each time step t. Early steps add a small amount of noise; later steps add more, so structures fade out gradually rather than all at once."
                )
                
                ExplanationItem(
                    icon: "arrow.down",
                    title: "Forward diffusion step",
                    text: "At each step we mix the current example with fresh Gaussian noise ε: zₜ = √(1-βₜ) · zₜ₋₁ + √(βₜ) · ε. Repeating this many times pushes zₜ towards a simple Gaussian distribution (pure noise)."
                )
                
                ExplanationItem(
                    icon: "graduationcap.fill",
                    title: "Why this matters for training",
                    text: "During training, we run the forward process to create noisy examples at different times t. The model then learns the reverse direction: given (zₜ, t), predict the noise and undo a single forward step. Chaining these learned steps gives the full reverse diffusion process used for generation."
                )
            }
        }
    }
}

struct NoisyLatentExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RichText(text: "After the forward process, we have noisy latent z_{t} - nearly pure Gaussian noise. This is the starting point for generation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "sparkles",
                    title: "Pure Noise",
                    text: "At the end of forward diffusion, the image is transformed into nearly pure Gaussian noise. All original structure and content have been erased."
                )
                
                ExplanationItem(
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    title: "Starting Point",
                    text: "This noisy latent z_{t} serves as the starting point for the reverse diffusion process. The model will iteratively remove noise to generate a new image."
                )
                
                ExplanationItem(
                    icon: "wand.and.stars",
                    title: "Generation Magic",
                    text: "The remarkable aspect of diffusion models is that they can transform this pure noise into a coherent, high-quality image that matches a text prompt, guided only by learned patterns."
                )
            }
        }
    }
}

struct ConditioningExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RichText(text: "The text prompt is encoded by τ_{θ} (tau) into conditioning embeddings. These guide the model to generate images that match the prompt.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "text.bubble.fill",
                    title: "Text Encoding",
                    text: "A text encoder (like CLIP) converts the user's text prompt into numerical embeddings. These embeddings capture the semantic meaning of the prompt."
                )
                
                ExplanationItem(
                    icon: "arrow.triangle.branch",
                    title: "Cross-Attention",
                    text: "The conditioning embeddings are fed into the U-Net via cross-attention layers. This allows the model to 'see' what the user wants and steer generation accordingly."
                )
                
                ExplanationItem(
                    icon: "target",
                    title: "Guided Generation",
                    text: "Without conditioning, the model would generate random images. With conditioning, it generates images that match the text description, making diffusion models controllable and useful."
                )
            }
        }
    }
}

struct UNetDenoiserExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The U-Net is the neural network that predicts and removes noise. It uses cross-attention to the text embeddings to steer generation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "network",
                    title: "U-Net Architecture",
                    text: "The U-Net has a U-shaped architecture with an encoder (downsampling) and decoder (upsampling) path. This design allows it to process images at multiple resolutions."
                )
                
                ExplanationItem(
                    icon: "eye.fill",
                    title: "Cross-Attention",
                    text: "Cross-attention layers connect the text conditioning to the image features. At each denoising step, the model attends to relevant parts of the text prompt to guide noise removal."
                )
                
                ExplanationItem(
                    icon: "arrow.counterclockwise",
                    title: "Iterative Denoising",
                    text: "The U-Net predicts the noise present in the image at each step. This prediction is subtracted to gradually remove noise, transforming pure noise into a coherent image over 20-50 steps."
                )
            }
        }
    }
}

struct CleanLatentExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("After iterative denoising we get clean latent z. High-frequency details are restored in latent space.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "checkmark.circle.fill",
                    title: "Noise Removed",
                    text: "After many denoising steps, the U-Net has successfully removed all noise. The latent representation now contains clean, structured features ready for decoding."
                )
                
                ExplanationItem(
                    icon: "sparkles",
                    title: "Detail Restoration",
                    text: "High-frequency details like textures, edges, and fine patterns are restored in latent space. The model has learned to reconstruct these details from the noisy input."
                )
                
                ExplanationItem(
                    icon: "arrow.right.circle.fill",
                    title: "Ready for Decoding",
                    text: "The clean latent z is now ready to be decoded back to pixel space, where it will become the final generated image."
                )
            }
        }
    }
}

struct DecoderExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The Variable Autoencoder (VAE) decoder D maps the clean latent back to pixel space, reconstructing the full-resolution image from the clean latent representation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "arrow.up.circle.fill",
                    title: "Upsampling",
                    text: "The decoder performs the inverse operation of the encoder. It upsamples the compressed latent representation back to full image resolution (e.g., 64×64 → 512×512)."
                )
                
                ExplanationItem(
                    icon: "photo.artframe",
                    title: "Pixel Reconstruction",
                    text: "Using learned upsampling layers, the decoder reconstructs RGB pixel values. It transforms the abstract latent features into concrete visual pixels."
                )
                
                ExplanationItem(
                    icon: "wand.and.stars.inverse",
                    title: "Final Output",
                    text: "The decoder produces the final high-resolution image in pixel space. This is the image that users see and interact with."
                )
            }
        }
    }
}

struct GeneratedImageExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The generated image x̃ is the final output. The reverse process has turned pure noise into a coherent image guided by the text prompt.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "sparkles",
                    title: "Complete Transformation",
                    text: "The generated image represents the complete transformation from pure noise to a coherent, high-quality image. This is the result of the entire reverse diffusion process."
                )
                
                ExplanationItem(
                    icon: "text.bubble.fill",
                    title: "Prompt Matching",
                    text: "The image matches the user's text prompt thanks to conditioning embeddings that guided the denoising process at every step."
                )
                
                ExplanationItem(
                    icon: "photo.fill",
                    title: "Pixel Space Output",
                    text: "The final image is in pixel space, ready to be displayed, saved, or used. It's a full-resolution image that looks like it was created by an artist."
                )
            }
        }
    }
}

// MARK: - Reusable Explanation Item

struct ExplanationItem: View {
    let icon: String
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.indigo)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                RichText(text: title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                RichText(text: text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - VAE (Variable Autoencoder) Explanation

private enum VAEExplanation {
    static let briefDescription = "A VAE compresses images into a lower-dimensional latent space and reconstructs them. In diffusion models, the encoder maps pixels to latents before noise is added; the decoder maps clean latents back to pixels after denoising."
    static let trainingDataEncoderBrief = "Training data are simply images in pixel space-the raw RGB inputs the model learns from. On the Latent Space lab, the Pixel Image panel represents this dataset view, independent of encoder internals."
    static let latentGridBrief = "The latent grid is the compressed output of the VAE encoder. Each cell holds encoded features; diffusion adds and removes noise in this space before the decoder reconstructs the final image."
}

struct VAEExplanationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The Variable Autoencoder (VAE) is a neural network that learns to compress images into a compact latent representation and decode them back. In latent diffusion models like Stable Diffusion, the VAE makes training and sampling much more efficient.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "arrow.down.circle.fill",
                    title: "Encoder",
                    text: "The encoder ε maps the high-resolution pixel image into a smaller latent grid (e.g. 64×64 with 4 channels). This compression preserves semantic and structural information while reducing compute. No diffusion happens in pixel space-only in latent space."
                )
                ExplanationItem(
                    icon: "cube.fill",
                    title: "Latent space",
                    text: "Latents are a compressed representation where each spatial position has a small vector of features. The diffusion process adds and removes noise in this space; operating here is far cheaper than in pixel space and still yields high-quality results after decoding."
                )
                ExplanationItem(
                    icon: "arrow.up.circle.fill",
                    title: "Decoder",
                    text: "After reverse diffusion, the decoder D maps the clean latent back to full-resolution pixel space. It upsamples and reconstructs fine detail (textures, edges) so the final output is a full-quality image."
                )
                ExplanationItem(
                    icon: "waveform.path",
                    title: "Why “variable”",
                    text: "In a standard VAE, the model learns a distribution over latents (mean and variance), so sampling is stochastic. In diffusion, the VAE is usually used in a deterministic way (encode/decode), but the name carries over from the architecture."
                )
            }
        }
    }
}

// Shown when user taps "Pixel Image" on the Latent Space lab.
struct VAETrainingDataEncoderExplanationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Training data for the diffusion model are images in pixel space: ordinary RGB photos or illustrations that the model learns from.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "photo.fill",
                    title: "Training data",
                    text: "Each training example starts as a high-resolution RGB image (e.g. 512×512 or 1024×1024). The dataset contains thousands or millions of such images covering diverse scenes, objects, and styles."
                )
                ExplanationItem(
                    icon: "brain.head.profile",
                    title: "No diffusion in pixels",
                    text: "Although the model is trained on pixel-space images, the actual diffusion process operates in a compressed latent space. The Pixel Image panel here is meant to represent the raw training data, before any encoding or noise is applied."
                )
            }
        }
    }
}

// Shown when user taps "Latent Grid" on the Latent Space lab.
struct VAELatentGridExplanationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The latent grid is the output of the VAE encoder: a lower-resolution grid where each cell holds a vector of features. Diffusion (noise addition and removal) happens entirely in this space.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "square.grid.3x3.fill",
                    title: "Spatial layout",
                    text: "The grid mirrors the spatial layout of the image at reduced resolution (e.g. 64×64). Each cell corresponds to a region of the original image and encodes local structure and appearance."
                )
                ExplanationItem(
                    icon: "waveform.path",
                    title: "Where diffusion runs",
                    text: "Forward diffusion adds Gaussian noise to this latent grid over many steps; reverse diffusion (denoising) removes it. The U-Net predicts noise in latent space, not in pixels."
                )
                ExplanationItem(
                    icon: "arrow.up.circle.fill",
                    title: "Back to pixels",
                    text: "After denoising, the clean latent grid is passed through the VAE decoder to produce the final high-resolution image. The colors in the lab view are a simplified visualization of latent magnitude or feature strength per cell."
                )
            }
        }
    }
}

// MARK: - Reverse Diffusion Explanation

struct ReverseDiffusionExplanationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The reverse diffusion process starts from a noisy latent (e.g. x₁₀) and iteratively removes noise using a trained U-Net. Each step predicts the noise εₜ and subtracts it to produce a cleaner latent, until the final clean image x₀ emerges.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                ExplanationItem(
                    icon: "waveform.path.ecg",
                    title: "Noise Prediction",
                    text: "At each timestep t, the U-Net takes the noisy latent xₜ and predicts the noise ε that was added. This prediction is used to compute a cleaner estimate xₜ₋₁ for the next step."
                )
                ExplanationItem(
                    icon: "arrow.counterclockwise",
                    title: "Iterative Denoising",
                    text: "Starting from nearly pure noise, the model runs 10–50 denoising steps. Each step removes a fraction of the predicted noise according to the scheduler, gradually revealing structure and detail."
                )
                ExplanationItem(
                    icon: "text.bubble.fill",
                    title: "Conditioning",
                    text: "Text prompts are encoded and fed to the U-Net via cross-attention. This guides the model to generate images that match the prompt instead of random outputs."
                )
                ExplanationItem(
                    icon: "checkmark.circle.fill",
                    title: "Clean Latent",
                    text: "After all steps, the latent is clean (x₀). The VAE decoder then maps it back to pixel space to produce the final generated image."
                )
            }
        }
    }
}

struct WhatIsDiffusionExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Diffusion models are a powerful class of generative AI models that create images by learning to reverse a gradual noise-adding process.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.indigo)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Forward Diffusion")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("The forward process gradually adds Gaussian noise to an image over many time steps. Starting from a clean image, noise is added according to a schedule until the image becomes nearly pure noise.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.indigo)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reverse Diffusion")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("The reverse process learns to predict and remove noise step by step. Starting from pure noise, the model iteratively denoises to generate a new image that matches a text prompt or conditioning signal.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.indigo)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why Diffusion Models?")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Diffusion models excel at generating high-quality, diverse images. They're stable to train and can produce photorealistic results. Popular examples include Stable Diffusion, DALL-E 2, and Midjourney.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

