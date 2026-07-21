import SwiftUI

/// ViewModel for the Related Maths screen
@MainActor
@Observable
final class RelatedMathsViewModel {

    // MARK: - Properties

    let headerDescription = "Explore the mathematics behind diffusion models"

    /// All math topics
    let topics = MathTopic.allCases.sorted { $0.orderNumber < $1.orderNumber }

    /// Currently expanded topic (nil if none)
    var expandedTopic: MathTopic?

    // MARK: - Initialization

    init(initialTopic: MathTopic? = nil) {
        self.expandedTopic = initialTopic
    }

    // MARK: - Gaussian Distribution State

    var gaussianMean: Double = 0.0
    var gaussianStdDev: Double = 1.0
    var gaussianViewMode: GaussianViewMode = .twoD

    enum GaussianViewMode: String, CaseIterable {
        case twoD = "1D Bell Curve"
        case threeD = "2D Surface (3D)"
    }

    // MARK: - Noise Schedule State

    var currentTimestep: Double = 500
    let totalTimesteps: Double = 1000
    let betaMin: Double = 0.0001
    let betaMax: Double = 0.02

    // MARK: - Forward Equation State

    var forwardTimestep: Double = 5
    var selectedForwardPart: ForwardEquationPart?

    // MARK: - Reverse Equation State

    var selectedReversePart: ReverseEquationPart?
    var reverseAnimationStep: Int = 0

    // MARK: - Loss Function State

    var isTrainingAnimating: Bool = false
    var currentLoss: Double = 0.5
    var lossViewMode: LossViewMode = .trainingSim
    var lossLandscapeRuggedness: Double = 0.5
    var lossLandscapeStyle: LossLandscapeStyle = .heightBased
    var lossLandscapePerspective: Bool = true

    enum LossViewMode: String, CaseIterable {
        case trainingSim = "Training Sim"
        case landscape3D = "3D Landscape"
    }

    private var trainingTask: Task<Void, Never>?
    
    // MARK: - Computed Properties (Noise Schedule)
    
    /// Beta value at current timestep (linear schedule)
    var beta_t: Double {
        betaMin + (betaMax - betaMin) * (currentTimestep / totalTimesteps)
    }
    
    /// Alpha value at current timestep
    var alpha_t: Double {
        1.0 - beta_t
    }
    
    /// Alpha bar (cumulative product) at current timestep
    var alpha_bar_t: Double {
        // Simplified approximation for visualization
        // In practice, this is the cumulative product of all alpha values
        let t = currentTimestep / totalTimesteps
        return exp(-0.5 * betaMin * totalTimesteps * t - 0.25 * (betaMax - betaMin) * totalTimesteps * t * t)
    }
    
    /// Square root of alpha bar
    var sqrt_alpha_bar_t: Double {
        sqrt(alpha_bar_t)
    }
    
    /// Square root of (1 - alpha bar)
    var sqrt_one_minus_alpha_bar_t: Double {
        sqrt(1.0 - alpha_bar_t)
    }
    
    /// Calculate beta at any timestep
    func betaAt(timestep: Double) -> Double {
        betaMin + (betaMax - betaMin) * (timestep / totalTimesteps)
    }
    
    /// Calculate alpha bar at any timestep
    func alphaBarAt(timestep: Double) -> Double {
        let t = timestep / totalTimesteps
        return exp(-0.5 * betaMin * totalTimesteps * t - 0.25 * (betaMax - betaMin) * totalTimesteps * t * t)
    }
    
    // MARK: - Computed Properties (Forward Equation)
    
    /// Signal weight at forward timestep
    var forwardSignalWeight: Double {
        sqrt(alphaBarAt(timestep: forwardTimestep * 100))
    }
    
    /// Noise weight at forward timestep
    var forwardNoiseWeight: Double {
        sqrt(1.0 - alphaBarAt(timestep: forwardTimestep * 100))
    }
    
    // MARK: - Actions
    
    func toggleTopic(_ topic: MathTopic) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if expandedTopic == topic {
                expandedTopic = nil
            } else {
                expandedTopic = topic
            }
        }
    }
    
    func startTrainingAnimation() {
        trainingTask?.cancel()
        trainingTask = nil
        isTrainingAnimating = true
        trainingTask = Task { await animateTrainingLoss() }
    }

    func stopTrainingAnimation() {
        trainingTask?.cancel()
        trainingTask = nil
        isTrainingAnimating = false
    }

    private func animateTrainingLoss() async {
        defer {
            trainingTask = nil
            if Task.isCancelled {
                isTrainingAnimating = false
            }
        }
        while !Task.isCancelled && isTrainingAnimating {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentLoss = max(0.01, currentLoss * 0.9 + Double.random(in: -0.02...0.05))
            }

            do {
                try await Task.sleep(for: .seconds(0.6))
            } catch {
                break
            }
        }
    }

    func resetTraining() {
        trainingTask?.cancel()
        trainingTask = nil
        currentLoss = 0.5
        isTrainingAnimating = false
    }
    
    func advanceReverseAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            reverseAnimationStep = (reverseAnimationStep + 1) % 10
        }
    }
}

