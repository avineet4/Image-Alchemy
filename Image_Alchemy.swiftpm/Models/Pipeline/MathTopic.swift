import SwiftUI

// Represents the different mathematical topics related to diffusion models
enum MathTopic: String, CaseIterable, Identifiable, Hashable {
    case probabilityBasics
    case randomVariables
    case vectorsAndDotProduct
    case gaussian
    case noiseSchedule
    case forwardEquation
    case reverseEquation
    case lossFunction
    case latentSpace
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .probabilityBasics:
            return "Probability Basics"
        case .randomVariables:
            return "Random Variables & Noise"
        case .vectorsAndDotProduct:
            return "Vectors & Dot Product"
        case .gaussian:
            return "Gaussian Distribution"
        case .noiseSchedule:
            return "Noise Schedule"
        case .forwardEquation:
            return "Forward Diffusion Equation"
        case .reverseEquation:
            return "Reverse Denoising Equation"
        case .lossFunction:
            return "Loss Function"
        case .latentSpace:
            return "Latent Space Diffusion"
        }
    }
    
    var subtitle: String {
        switch self {
        case .probabilityBasics:
            return "Events, probabilities, and expectations"
        case .randomVariables:
            return "From scalar noise to random variables"
        case .vectorsAndDotProduct:
            return "How images become vectors we can compute with"
        case .gaussian:
            return "The foundation of diffusion - bell curve & noise"
        case .noiseSchedule:
            return "How noise increases over timesteps"
        case .forwardEquation:
            return "Noisy image = signal (fading) + noise (growing)"
        case .reverseEquation:
            return "How U-Net predicts and removes noise"
        case .lossFunction:
            return "Training objective: minimize noise prediction error"
        case .latentSpace:
            return "From pixel space to compressed representations – where modern diffusion happens"
        }
    }
    
    var icon: String {
        switch self {
        case .probabilityBasics:
            return "die.face.5"
        case .randomVariables:
            return "sparkles"
        case .vectorsAndDotProduct:
            return "square.grid.3x3"
        case .gaussian:
            return "chart.xyaxis.line"
        case .noiseSchedule:
            return "chart.line.uptrend.xyaxis"
        case .forwardEquation:
            return "arrow.right.circle"
        case .reverseEquation:
            return "arrow.left.circle"
        case .lossFunction:
            return "function"
        case .latentSpace:
            return "square.stack.3d.down.right"
        }
    }
    
    var color: Color {
        switch self {
        case .probabilityBasics:
            return .teal
        case .randomVariables:
            return .mint
        case .vectorsAndDotProduct:
            return .indigo
        case .gaussian:
            return .blue
        case .noiseSchedule:
            return .orange
        case .forwardEquation:
            return .green
        case .reverseEquation:
            return .purple
        case .lossFunction:
            return .red
        case .latentSpace:
            return .cyan
        }
    }
    
    var orderNumber: Int {
        switch self {
        case .probabilityBasics: return 0
        case .randomVariables: return 1
        case .vectorsAndDotProduct: return 2
        case .gaussian: return 3
        case .noiseSchedule: return 4
        case .forwardEquation: return 5
        case .reverseEquation: return 6
        case .lossFunction: return 7
        case .latentSpace: return 8
        }
    }
}
