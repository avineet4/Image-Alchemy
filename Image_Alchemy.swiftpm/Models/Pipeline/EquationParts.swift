import SwiftUI

// MARK: - Forward Equation Parts

enum ForwardEquationPart: String, CaseIterable {
    case result      // x_t
    case signal      // √ᾱ_t · x_{0}
    case noise       // √(1-ᾱ_t) · ε
    
    var title: String {
        switch self {
        case .result: return "Noisy Image"
        case .signal: return "Signal Component"
        case .noise: return "Noise Component"
        }
    }
    
    var explanation: String {
        switch self {
        case .result:
            return "The noisy image at timestep t. This is what we get after adding noise to the original image. As t increases, xₜ becomes more noisy until it's pure noise at t=T."
        case .signal:
            return "√ᾱₜ · x₀ is the SIGNAL component. As t increases, √ᾱₜ decreases from 1 toward 0, fading the original image. This preserves the structure of the original image."
        case .noise:
            return "√(1-ᾱₜ) · ε is the NOISE component. ε is sampled from N(0,1). As t increases, this term dominates, eventually replacing the signal with pure noise."
        }
    }
    
    var example: String? {
        switch self {
        case .result:
            return "t=0: x₀ (original)\nt=500: x₅₀₀ (noisy)\nt=T: pure noise"
        case .signal:
            return "t=0: √ᾱ₀ ≈ 1.0\nt=T/2: √ᾱₜ/₂ ≈ 0.5\nt=T: √ᾱₜ ≈ 0"
        case .noise:
            return "t=0: √(1-ᾱ₀) ≈ 0\nt=T/2: √(1-ᾱₜ/₂) ≈ 0.7\nt=T: √(1-ᾱₜ) ≈ 1"
        }
    }
    
    var color: Color {
        switch self {
        case .result: return .purple
        case .signal: return .blue
        case .noise: return .red
        }
    }
}

// MARK: - Reverse Equation Parts

enum ReverseEquationPart: String, CaseIterable {
    case result      // x_{t-1}
    case scaling     // 1/√α_t
    case denoise     // x_t - (β_t/√(1-ᾱ_t)) · ε_{θ}
    case stochastic  // σ_t · z
    
    var title: String {
        switch self {
        case .result: return "Denoised Output"
        case .scaling: return "Scaling Factor"
        case .denoise: return "Denoising Term"
        case .stochastic: return "Stochastic Term"
        }
    }
    
    var explanation: String {
        switch self {
        case .result:
            return "xₜ₋₁ is the slightly less noisy image. Each reverse step removes a bit of noise."
        case .scaling:
            return "1/√αₜ scales the result. This compensates for the scaling in the forward process."
        case .denoise:
            return "The main denoising: subtract the predicted noise ε₀ (from U-Net) scaled appropriately."
        case .stochastic:
            return "σₜ·z adds a small amount of fresh noise. This helps with generation diversity."
        }
    }
    
    var example: String? {
        switch self {
        case .result:
            return "Step 1: xₜ → xₜ₋₁\nStep T: x₁ → x₀\n(clean image)"
        case .scaling:
            return "1/√αₜ undoes the\nforward scaling"
        case .denoise:
            return "xₜ − (noise term)\nU-Net predicts ε₀"
        case .stochastic:
            return "σₜ = noise schedule\nz ~ N(0,1)"
        }
    }
    
    var color: Color {
        switch self {
        case .result: return .purple
        case .scaling: return .orange
        case .denoise: return .green
        case .stochastic: return .gray
        }
    }
}
