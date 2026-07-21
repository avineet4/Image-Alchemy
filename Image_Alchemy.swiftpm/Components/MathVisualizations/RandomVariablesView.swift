import SwiftUI

// MARK: - Random Variable Equation Parts

enum RandomVariableEquationPart: String, CaseIterable {
    case variable      // ε
    case distribution // ~
    case normal       // N
    case parameters   // (0, 1)
    
    var title: String {
        switch self {
        case .variable: return "Random Variable"
        case .distribution: return "Distribution Symbol"
        case .normal: return "Normal Distribution"
        case .parameters: return "Parameters"
        }
    }
    
    var explanation: String {
        switch self {
        case .variable:
            return "ε (epsilon) is a random variable-a quantity that takes different values each time we sample it. In diffusion models, ε represents pure Gaussian noise added to images."
        case .distribution:
            return "The tilde (~) means 'is distributed as' or 'follows the distribution'. It connects the random variable to its probability distribution."
        case .normal:
            return "N stands for the Normal (Gaussian) distribution-a bell-shaped probability curve. This is the most common distribution for noise in diffusion models."
        case .parameters:
            return "The numbers (0, 1) are the parameters: 0 is the mean (center) and 1 is the variance (spread). This makes it a 'standard' normal distribution."
        }
    }
    
    var example: String? {
        switch self {
        case .variable:
            return "ε₁ = 0.342\nε₂ = -1.127\nε₃ = 0.891"
        case .distribution:
            return "X ~ Uniform\nY ~ Poisson\nZ ~ N(0,1)"
        case .normal:
            return "N(μ, σ²)\nμ = mean\nσ² = variance"
        case .parameters:
            return "N(0, 1) = standard\nN(5, 2) = shifted\nN(0, 4) = wider"
        }
    }
}

struct RandomVariablesView: View {
    @State private var viewModel = RandomVariablesViewModel()
    @State private var selectedPart: RandomVariableEquationPart?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard normal random variable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 1) {
                        RandomVariablePartButton(
                            text: "ε",
                            part: .variable,
                            selectedPart: $selectedPart
                        )
                        
                        RandomVariablePartButton(
                            text: "~",
                            part: .distribution,
                            selectedPart: $selectedPart
                        )
                        
                        RandomVariablePartButton(
                            text: "N",
                            part: .normal,
                            selectedPart: $selectedPart
                        )
                        
                        RandomVariablePartButton(
                            text: "(0, 1)",
                            part: .parameters,
                            selectedPart: $selectedPart
                        )
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
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                
                if let selectedPart = selectedPart {
                    RandomVariableExplanationBox(part: selectedPart)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
            .animation(.smooth(duration: 0.35), value: selectedPart?.rawValue)

            NoiseGrid2DView(grid: viewModel.noiseGrid)
                .animation(.smooth(duration: 0.3), value: viewModel.noiseGrid)

            HStack(spacing: 12) {
                Button {
                    viewModel.resampleAll()
                } label: {
                    Label("Resample all", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)

                Button {
                    viewModel.drawSingleSample()
                } label: {
                    Label("Draw one ε", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isDrawingSample)
            }

            Divider()

            if let sample = viewModel.lastDrawnSample {
                HStack(spacing: 12) {
                    Text("Last drawn:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(sample, format: .number.precision(.fractionLength(3)))
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.mint)
                    Text("(one sample of ε)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.mint.opacity(0.12))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            NoiseHistogramView(samples: viewModel.samples)
                .frame(height: 100)

            NoiseSamplesStripView(
                samples: viewModel.samples,
                selectedIndex: viewModel.selectedSampleIndex,
                onSelect: viewModel.selectSample
            )

            RichText(text: "A **random variable** is a quantity that takes different values according to some probability rule. In diffusion, ε is a random variable that represents pure Gaussian noise.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Why this matters")
                    .font(.headline)

                bullet("Each sample of ε is different, so every run of the model can create a different image.")
                bullet("The **distribution** of ε (Gaussian) is what gives the noise its characteristic \"snow-like\" look.")
                bullet("During training, the model learns to **predict ε** from a noisy image xₜ and timestep t.")
            }
        }
        .padding()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            RichText(text: text)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Supporting Views

private struct NoiseGrid2DView: View {
    let grid: [[Double]]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("2D noise patch (like diffusion adds to images)")
                .font(.caption)
                .foregroundStyle(.secondary)

            let size = grid.count
            let cellSize: CGFloat = min(10, 280 / CGFloat(size))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 1), count: size), spacing: 1) {
                ForEach(0..<(size * size), id: \.self) { index in
                    let row = index / size
                    let col = index % size
                    RoundedRectangle(cornerRadius: 1)
                        .fill(NoiseSamplesStripView.color(for: grid[row][col]))
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
    }
}

private struct NoiseHistogramView: View {
    let samples: [Double]
    private let binCount = 12
    private let range = (-2.5, 2.5)

    var body: some View {
        let bins = computeBins()
        let maxCount = bins.max() ?? 1

        VStack(alignment: .leading, spacing: 6) {
            Text("Distribution of samples (bell curve)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(bins.indices, id: \.self) { i in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.mint.opacity(0.5), .mint],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(4, CGFloat(bins[i]) / CGFloat(maxCount) * 60))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 70)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemBackground))
            )

            HStack {
                Text("−2.5")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("+2.5")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func computeBins() -> [Int] {
        var bins = Array(repeating: 0, count: binCount)
        let (lo, hi) = range
        let step = (hi - lo) / Double(binCount)
        for s in samples {
            let idx = Int((s - lo) / step)
            let clamped = max(0, min(binCount - 1, idx))
            bins[clamped] += 1
        }
        return bins
    }
}

private struct NoiseSamplesStripView: View {
    let samples: [Double]
    var selectedIndex: Int? = nil
    var onSelect: ((Int?) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal) {
                HStack(spacing: 3) {
                    ForEach(samples.indices, id: \.self) { index in
                        let isSelected = selectedIndex == index
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Self.color(for: samples[index]))
                            .frame(width: 12, height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(isSelected ? Color.mint : .clear, lineWidth: 2)
                            )
                            .scaleEffect(isSelected ? 1.2 : 1.0)
                            .animation(.smooth(duration: 0.2), value: selectedIndex)
                            .onTapGesture {
                                onSelect?(isSelected ? nil : index)
                            }
                    }
                }
                .padding(.horizontal, 4)
            }
            .scrollIndicators(.hidden)
            .frame(height: 20)

            if let idx = selectedIndex, idx < samples.count {
                Text("Sample \(idx + 1): ε = \(samples[idx], format: .number.precision(.fractionLength(3)))")
                    .font(.caption)
                    .foregroundStyle(.mint)
            } else {
                Text("Tap a square to see its value. Each is one sample of ε from N(0,1).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    static func color(for value: Double) -> Color {
        let t = max(-2, min(2, value)) / 2
        if t >= 0 {
            return Color(red: 0.4 + 0.4 * t, green: 0.7, blue: 0.6)
        } else {
            let p = -t
            return Color(red: 0.3, green: 0.5 + 0.3 * p, blue: 0.7)
        }
    }
}

// MARK: - Equation Part Button

private struct RandomVariablePartButton: View {
    let text: String
    let part: RandomVariableEquationPart
    @Binding var selectedPart: RandomVariableEquationPart?
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

private struct RandomVariableExplanationBox: View {
    let part: RandomVariableEquationPart
    
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
