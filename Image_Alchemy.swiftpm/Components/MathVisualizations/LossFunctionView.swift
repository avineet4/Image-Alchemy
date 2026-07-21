import SwiftUI

// MARK: - Loss Equation Parts

enum LossEquationPart: String, CaseIterable {
    case loss           // L
    case expectation    // E[...]
    case actualNoise    // ε
    case predictedNoise // ε_{θ}(x_{t}, t)
    case normSquared    // ‖...‖²
    
    var title: String {
        switch self {
        case .loss: return "Loss"
        case .expectation: return "Expectation"
        case .actualNoise: return "Actual Noise"
        case .predictedNoise: return "Predicted Noise"
        case .normSquared: return "Squared Norm (MSE)"
        }
    }
    
    var explanation: String {
        switch self {
        case .loss:
            return "L is the loss value we minimize during training. Lower L means the model predicts noise more accurately."
        case .expectation:
            return "E[...] is the expectation (average) over many training examples-images, timesteps, and noise samples."
        case .actualNoise:
            return "ε is the actual noise that was added to the image. We know this during training because we generate it."
        case .predictedNoise:
            return "ε₀(xₜ, t) is the noise predicted by the model (U-Net) with parameters θ, given noisy image xₜ and timestep t."
        case .normSquared:
            return "‖…‖² is the squared Euclidean norm-sum of squared differences. This is Mean Squared Error (MSE)."
        }
    }
    
    var example: String? {
        switch self {
        case .loss:
            return "L = 0.05 → good\nL = 0.5 → poor"
        case .expectation:
            return "E over batches\nof training data"
        case .actualNoise:
            return "ε ~ N(0, 1)\n(sampled once)"
        case .predictedNoise:
            return "U-Net output\nsame shape as ε"
        case .normSquared:
            return "‖a − b‖² =\nΣᵢ (aᵢ − bᵢ)²"
        }
    }
}

// Interactive visualization of the loss function (training objective)
struct LossFunctionView: View {
    @Binding var isAnimating: Bool
    @Binding var currentLoss: Double
    let onStartTraining: () -> Void
    let onStopTraining: () -> Void
    let onReset: () -> Void
    @State private var selectedPart: LossEquationPart?
    
    var body: some View {
        VStack(spacing: 20) {
            // Interactive equation display (same pattern as VectorsAndDotProductView)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Loss function (training objective)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 1) {
                        LossPartButton(text: "L", part: .loss, selectedPart: $selectedPart)
                        ScriptText(raw: "=", baseSize: 28)
                        LossPartButton(text: "E[", part: .expectation, selectedPart: $selectedPart)
                        LossPartButton(text: "‖ε", part: .actualNoise, selectedPart: $selectedPart)
                        ScriptText(raw: " - ", baseSize: 28)
                        LossPartButton(text: "ε_{θ}(x_{t}, t)", part: .predictedNoise, selectedPart: $selectedPart)
                        LossPartButton(text: "‖^{2} ]", part: .normSquared, selectedPart: $selectedPart)
                    }
                    .padding(.vertical, 12)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.7))
                        Text("Tap any part of the equation to learn more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .animation(.smooth(duration: 0.2), value: selectedPart)
                .padding()
                .frame(maxWidth: 370, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                
                if let selectedPart = selectedPart {
                    LossExplanationBox(part: selectedPart)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
            .animation(.smooth(duration: 0.35), value: selectedPart?.rawValue)
            
            // Side-by-side noise comparison
            HStack(spacing: 20) {
                NoiseBox(
                    title: "Actual Noise",
                    symbol: "ε",
                    color: .blue,
                    pattern: actualNoisePattern
                )
                
                Text("vs")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                NoiseBox(
                    title: "Predicted",
                    symbol: "ε_{θ}",
                    color: .orange,
                    pattern: predictedNoisePattern
                )
            }
            .padding(.horizontal)
            
            // Loss display
            VStack(spacing: 8) {
                Text("MSE Loss")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(currentLoss, format: .number.precision(.fractionLength(4)))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(lossColor)
                    
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .opacity(isAnimating ? 1 : 0)
                }
                
                Text("← minimize this!")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            .padding(.horizontal)
            
            // Training controls
            HStack(spacing: 10) {
                Button {
                    if isAnimating {
                        onStopTraining()
                    } else {
                        onStartTraining()
                    }
                } label: {
                    Label(
                        isAnimating ? "Pause" : "Train",
                        systemImage: isAnimating ? "pause.fill" : "play.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .glassEffect(.regular.tint(isAnimating ? Color.orange : Color.green).interactive(), in: Capsule())
                }
                
                Button {
                    onReset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .accessibilityLabel("Reset")
                .glassEffect(.regular.tint(Color.secondary.opacity(0.3)).interactive(), in: Circle())
            }
            
            // Explanation
            Text("Training: predict noise, compare to actual, backpropagate error")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var lossColor: Color {
        if currentLoss > 0.3 {
            return .red
        } else if currentLoss > 0.1 {
            return .orange
        } else {
            return .green
        }
    }
    
    // Generate random-looking noise patterns
    private var actualNoisePattern: [CGFloat] {
        [0.3, 0.7, 0.5, 0.8, 0.2, 0.6, 0.4, 0.9, 0.1, 0.5,
         0.6, 0.2, 0.8, 0.3, 0.7, 0.4, 0.9, 0.1, 0.5, 0.6]
    }
    
    private var predictedNoisePattern: [CGFloat] {
        let accuracy = 1.0 - currentLoss
        return actualNoisePattern.map { value in
            let error = CGFloat.random(in: -0.3...0.3) * CGFloat(1.0 - accuracy)
            return max(0, min(1, value + error))
        }
    }
}

// Visual noise pattern box
private struct NoiseBox: View {
    let title: String
    let symbol: String
    let color: Color
    let pattern: [CGFloat]
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Noise pattern visualization
            NoisePatternCanvas(pattern: pattern, color: color)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
            
            ScriptText(raw: symbol, baseSize: 16, weight: .medium)
                .foregroundStyle(color)
        }
    }
}

// Canvas for drawing noise pattern
private struct NoisePatternCanvas: View {
    let pattern: [CGFloat]
    let color: Color
    
    var body: some View {
        Canvas { context, size in
            let gridSize = 4
            let cellWidth = size.width / CGFloat(gridSize)
            let cellHeight = size.height / CGFloat(gridSize)
            
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let index = row * gridSize + col
                    let value = index < pattern.count ? pattern[index] : 0.5
                    
                    let rect = CGRect(
                        x: CGFloat(col) * cellWidth,
                        y: CGFloat(row) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )
                    
                    context.fill(
                        Rectangle().path(in: rect),
                        with: .color(color.opacity(Double(value)))
                    )
                }
            }
        }
    }
}

// MARK: - Equation Part Button

private struct LossPartButton: View {
    let text: String
    let part: LossEquationPart
    @Binding var selectedPart: LossEquationPart?
    var delay: Double = 0
    
    var isSelected: Bool {
        selectedPart == part
    }
    
    @State private var appeared = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedPart == part {
                    selectedPart = nil
                } else {
                    selectedPart = part
                }
            }
        } label: {
            ScriptText(
                raw: text,
                baseSize: 24,
                weight: isSelected ? .semibold : .regular
            )
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.secondary.opacity(0.2) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.secondary.opacity(0.4) : .clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 6)
        .onAppear {
            withAnimation(.smooth(duration: 0.4).delay(delay)) {
                appeared = true
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Explanation Box

private struct LossExplanationBox: View {
    let part: LossEquationPart
    
    var body: some View {
        ZStackLayout(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(.secondary)
                        .frame(width: 8, height: 8)
                    
                    Text(part.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                HStack(alignment: .top, spacing: 16) {
                    Text(part.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let example = part.example {
                        Divider()
                            .frame(height: 60)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Example:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Text(example)
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundStyle(.primary)
                        }
                        .frame(minWidth: 120, alignment: .leading)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 400, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}
