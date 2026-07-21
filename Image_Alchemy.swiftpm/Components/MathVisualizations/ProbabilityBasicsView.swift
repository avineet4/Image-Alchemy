import SwiftUI
import Charts

// MARK: - Probability Equation Parts

enum ProbabilityEquationPart: String, CaseIterable {
    case notation
    case event
    case valueRange
    
    var title: String {
        switch self {
        case .notation: return "Probability Function"
        case .event: return "Event"
        case .valueRange: return "Probability Range"
        }
    }
    
    var explanation: String {
        switch self {
        case .notation:
            return "P denotes the probability function. It maps events to numbers between 0 and 1, representing how likely the event is to occur."
        case .event:
            return "A represents an event-something that can happen. Events can be simple (like 'coin shows heads') or complex (like 'pixel is bright')."
        case .valueRange:
            return "Probabilities are always between 0 and 1. P(A) = 0 means A never happens, P(A) = 1 means A always happens, and P(A) = 0.5 means A happens half the time."
        }
    }
    
    var example: String? {
        switch self {
        case .notation:
            return "P(heads) = 0.5\nP(tails) = 0.5"
        case .event:
            return "A = 'coin shows heads'\nA = 'pixel is bright'"
        case .valueRange:
            return "P(impossible) = 0\nP(certain) = 1\nP(fair coin heads) = 0.5"
        }
    }
}

struct ProbabilityBasicsView: View {
    @State private var viewModel = ProbabilityBasicsViewModel()
    @State private var selectedPart: ProbabilityEquationPart?
    @State private var equationAppeared = false

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Probability of an event A")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(equationAppeared ? 1 : 0)
                        .offset(y: equationAppeared ? 0 : 4)
                    
                    HStack(spacing: 1) {
                        ProbabilityPartButton(
                            text: "P",
                            part: .notation,
                            selectedPart: $selectedPart,
                            delay: 0
                        )
                        
                        Text("(")
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .opacity(equationAppeared ? 1 : 0)
                            .scaleEffect(equationAppeared ? 1 : 0.8)
                        
                        ProbabilityPartButton(
                            text: "A",
                            part: .event,
                            selectedPart: $selectedPart,
                            delay: 0.05
                        )
                        
                        Text(")")
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .opacity(equationAppeared ? 1 : 0)
                            .scaleEffect(equationAppeared ? 1 : 0.8)
                        
                        ProbabilityPartButton(
                            text: " ∈ [0, 1]",
                            part: .valueRange,
                            selectedPart: $selectedPart,
                            delay: 0.1
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
                    .opacity(equationAppeared ? 1 : 0)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .onAppear {
                    withAnimation(.smooth(duration: 0.5)) {
                        equationAppeared = true
                    }
                }
                
                if let selectedPart = selectedPart {
                    ProbabilityExplanationBox(part: selectedPart)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
            .animation(.smooth(duration: 0.35), value: selectedPart?.rawValue)

            EventProbabilitySection(
                probability: viewModel.eventProbability,
                onSet: viewModel.setEventProbability
            )

            Divider()

            CoinFlipSimulationView(
                flips: viewModel.coinFlips,
                isFlipping: viewModel.isFlipping,
                empiricalProbability: viewModel.empiricalProbability,
                onFlip: viewModel.flipCoin,
                onReset: viewModel.resetCoinFlips
            )

            Divider()

            ExpectationSimulationView(
                outcomes: ProbabilityBasicsViewModel.expectationOutcomes,
                samples: viewModel.expectationSamples,
                theoreticalExpectation: viewModel.theoreticalExpectation,
                sampleExpectation: viewModel.sampleExpectation,
                onSample: viewModel.addExpectationSample,
                onReset: viewModel.resetExpectationSamples
            )

            Divider()

            InteractiveProbabilityBarsView()

            RichText(text: "In diffusion models, we treat many things as random: noise, images, and even text prompts. Probability tells us **how likely** different outcomes are.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Core ideas")
                    .font(.headline)

                bullet("An **event** is something that can happen (e.g. \"pixel is bright\").")
                bullet("A **probability** is a number between 0 and 1 describing how likely the event is.")
                bullet("An **expectation** E[X] is the average value of a random quantity X over many trials.")
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

// MARK: - Event probability section (unified bar + pie + values)

private struct EventProbabilitySection: View {
    let probability: Double
    let onSet: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Set P(A)")
                .font(.subheadline.weight(.semibold))

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Slider(value: Binding(get: { probability }, set: { onSet($0) }), in: 0...1)
                        .tint(.teal)

                    HStack(spacing: 10) {
                        Text("P(A) = \(probability, format: .number.precision(.fractionLength(2)))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.teal)
                            .contentTransition(.numericText())
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text("P(not A) = \(1 - probability, format: .number.precision(.fractionLength(2)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                    .animation(.smooth(duration: 0.2), value: probability)
                }

                ProbabilityPieChart(probability: probability)
                    .frame(width: 80, height: 80)
                    .animation(.smooth(duration: 0.25), value: probability)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )

            Text("Drag the slider to set the probability of event A.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Supporting Views

private struct ProbabilityPieChart: View {
    let probability: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemBackground), lineWidth: 12)

            Circle()
                .trim(from: 0, to: probability)
                .stroke(
                    LinearGradient(
                        colors: [.teal, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.4), value: probability)

            VStack(spacing: 0) {
                Text("P(A)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(probability, format: .percent.precision(.fractionLength(0)))
                    .font(.caption.weight(.semibold))
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.3), value: probability)
            }
        }
    }
}

private struct CoinFlipSimulationView: View {
    let flips: [Bool]
    let isFlipping: Bool
    let empiricalProbability: Double
    let onFlip: () -> Void
    let onReset: () -> Void

    private var flipCounts: (heads: Int, tails: Int) {
        flips.reduce((0, 0)) { ($0.0 + ($1 ? 1 : 0), $0.1 + ($1 ? 0 : 1)) }
    }
    private var headsCount: Int { flipCounts.heads }
    private var tailsCount: Int { flipCounts.tails }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coin flip: empirical probability")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 16) {
                Button {
                    onFlip()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.85, green: 0.7, blue: 0.15))
                            .frame(width: 64, height: 64)
                            .shadow(color: .black.opacity(0.2), radius: isFlipping ? 8 : 4, y: isFlipping ? 4 : 2)

                        Circle()
                            .fill(.yellow)
                            .frame(width: 50, height: 50)

                        Image(systemName: "dollarsign")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(14)
                    }
                    .scaleEffect(isFlipping ? 1.08 : 1)
                    .rotation3DEffect(
                                .degrees(isFlipping ? 1800 : 0),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.5
                            )
                    .animation(.easeInOut(duration: 0.5), value: isFlipping)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isFlipping)
                }
                .buttonStyle(.plain)
                .disabled(isFlipping)

                VStack(alignment: .leading, spacing: 4) {
                    if flips.isEmpty {
                        Text("Tap the coin to flip")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 8) {
                            Text("Heads: \(headsCount)")
                                .font(.subheadline)
                            Text("Tails: \(tailsCount)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text("P(heads) ≈ \(empiricalProbability, format: .number.precision(.fractionLength(3)))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.teal)
                            .contentTransition(.numericText())
                        Text("Theoretical: 0.5 • Flips: \(flips.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if !flips.isEmpty {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical) {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 14), spacing: 4)],
                                spacing: 4
                            ) {
                                ForEach(Array(flips.enumerated()), id: \.offset) { index, isHeads in
                                    CoinFlipDot(isHeads: isHeads, index: index)
                                        .id(index)
                                }
                            }
                            .padding(4)
                        }
                        .scrollIndicators(.hidden)
                        .frame(height: 60)
                        .onChange(of: flips.count) { _, newCount in
                            guard newCount > 0 else { return }
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(newCount - 1, anchor: .bottom)
                            }
                        }
                    }

                    Button(action: onReset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(10)
                            .frame(minWidth: 35, minHeight: 35)
                            // .contentShape(Circle())
                    }
                    .glassEffect(.regular.tint(.teal).interactive(), in: .circle)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

private struct CoinFlipDot: View {
    let isHeads: Bool
    let index: Int
    @State private var appeared = false

    var body: some View {
        Circle()
            .fill(isHeads ? Color.orange : Color.gray.opacity(0.6))
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(isHeads ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(appeared ? 1 : 0)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(Double(index) * 0.02)) {
                    appeared = true
                }
            }
    }
}

private struct ExpectationSimulationView: View {
    let outcomes: [(value: Double, weight: Double)]
    let samples: [Double]
    let theoreticalExpectation: Double
    let sampleExpectation: Double
    let onSample: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expectation E[X] = Σ value × P(value)")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Outcomes: X ∈ {1, 2, 3} with P(1)=0.2, P(2)=0.5, P(3)=0.3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("E[X] = \(theoreticalExpectation, format: .number.precision(.fractionLength(2)))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.teal)
                }

                Spacer()

                Button(action: onSample) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body.weight(.medium))
                        Text("Sample")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .glassEffect(.regular.tint(.teal).interactive(), in: .capsule)

                if !samples.isEmpty {
                    Button(action: onReset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(8)
                            .frame(minWidth: 25, minHeight: 25)
                    }
                    .glassEffect(.regular.tint(.teal).interactive(), in: .circle)
                }
            }

            if !samples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Sample average:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(sampleExpectation, format: .number.precision(.fractionLength(3)))
                            .font(.subheadline.weight(.medium))
                            .contentTransition(.numericText())
                            .animation(.smooth(duration: 0.25), value: sampleExpectation)
                        Text("(n = \(samples.count))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(Array(samples.enumerated()), id: \.offset) { index, value in
                                ExpectationSamplePill(value: value, index: index)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 32)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.smooth(duration: 0.3), value: samples.isEmpty)
    }
}

private struct ExpectationSamplePill: View {
    let value: Double
    let index: Int
    @State private var appeared = false

    var body: some View {
        Text("\(Int(value))")
            .font(.caption)
            .fontWeight(.medium)
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.teal.opacity(0.25))
            )
            .overlay(
                Capsule()
                    .stroke(Color.teal.opacity(0.3), lineWidth: 1)
            )
            .offset(x: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Probability scale (card-based, interactive)

private struct InteractiveProbabilityBarsView: View {
    private static let labels = ["Low", "Medium", "High"]
    private static let values: [Double] = [0.2, 0.5, 0.9]

    @State private var selectedIndex: Int? = nil
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Probability scale")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 12) {
                ForEach(Array(Self.labels.enumerated()), id: \.offset) { index, label in
                    ProbabilityScaleCard(
                        label: label,
                        value: Self.values[index],
                        isSelected: selectedIndex == index,
                        appearDelay: Double(index) * 0.08,
                        appeared: appeared
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                            selectedIndex = selectedIndex == index ? nil : index
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemBackground))
            )
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appeared = true
                }
            }

            Text("Probabilities are numbers between 0 and 1 (or 0% and 100%). Low means unlikely, high means likely. Tap a card to see how we refer to different levels.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ProbabilityScaleCard: View {
    let label: String
    let value: Double
    let isSelected: Bool
    let appearDelay: Double
    let appeared: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text("\(Int(value * 100))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .teal : .primary)
                    .contentTransition(.numericText())

                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .teal : .secondary)

                // Level indicator bar
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isSelected ? Color.teal.opacity(0.5) : Color.primary.opacity(0.12))
                        .frame(width: geo.size.width * value, height: 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.teal.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.teal.opacity(0.6) : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.45, dampingFraction: 0.75).delay(appearDelay), value: appeared)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Equation Part Button

private struct ProbabilityPartButton: View {
    let text: String
    let part: ProbabilityEquationPart
    @Binding var selectedPart: ProbabilityEquationPart?
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

private struct ProbabilityExplanationBox: View {
    let part: ProbabilityEquationPart
    @State private var contentVisible = false

    var body: some View {
        ZStackLayout(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.secondary)
                        .frame(width: 8, height: 8)
                        .opacity(contentVisible ? 1 : 0)
                        .scaleEffect(contentVisible ? 1 : 0.5)

                    Text(part.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .opacity(contentVisible ? 1 : 0)
                        .offset(x: contentVisible ? 0 : -8)
                }

                HStack(alignment: .top, spacing: 16) {
                    Text(part.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(contentVisible ? 1 : 0)
                        .offset(y: contentVisible ? 0 : 6)

                    if let example = part.example {
                        Divider()
                            .frame(height: 60)
                            .opacity(contentVisible ? 1 : 0)

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
                        .opacity(contentVisible ? 1 : 0)
                        .offset(x: contentVisible ? 0 : 10)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 400, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .id(part)
            .onAppear {
                withAnimation(.smooth(duration: 0.35)) {
                    contentVisible = true
                }
            }
        }
    }
}
