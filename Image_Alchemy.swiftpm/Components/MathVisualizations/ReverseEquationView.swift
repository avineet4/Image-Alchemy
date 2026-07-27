import SwiftUI

// Interactive visualization of the reverse denoising equation
struct ReverseEquationView: View {
    @Binding var selectedPart: ReverseEquationPart?
    @Binding var animationStep: Int
    let onAdvanceAnimation: () -> Void
    
    private let totalSteps = 10
    
    @State private var isPlaying = false
    @State private var playTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 24) {
            // Interactive equation display
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reverse denoising equation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ReversePartButton(text: "x_{t-1}", part: .result, selectedPart: $selectedPart)
                            ScriptText(raw: "=", baseSize: 28)
                            ReversePartButton(text: "1/√α_{t}", part: .scaling, selectedPart: $selectedPart)
                            ScriptText(raw: "·", baseSize: 28)
                            ScriptText(raw: "(", baseSize: 28)
                            ReversePartButton(text: "x_{t} - β_{t}/√(1-ᾱ_{t})·ε_{θ}", part: .denoise, selectedPart: $selectedPart)
                            ScriptText(raw: ")", baseSize: 28)
                            ScriptText(raw: "+", baseSize: 28)
                            ReversePartButton(text: "σ_{t}·z", part: .stochastic, selectedPart: $selectedPart)
                        }
                        .padding(.vertical, 12)
                    // }
                    
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
                .frame(maxWidth: 520, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                
                if let selectedPart = selectedPart {
                    ReverseExplanationBox(part: selectedPart)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
            .animation(.smooth(duration: 0.35), value: selectedPart?.rawValue)
            
            // Noise -> image blend at current step
            ReverseBlendVisualization(currentStep: animationStep, totalSteps: totalSteps)
                .frame(height: 130)
                .padding(.horizontal)
            
            // Denoising path (noise level vs step)
            ReversePathGraph(currentStep: animationStep, totalSteps: totalSteps)
                .frame(height: 100)
                .padding(.horizontal)
            
            // Iteration controls and visualization
            VStack(spacing: 16) {
                HStack {
                    Text("Denoising steps")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(animationStep + 1) / \(totalSteps)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button {
                        withAnimation(.snappy(duration: 0.15)) {
                            togglePlay()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                    }
                    .glassEffect(.regular.tint(.purple).interactive(), in: .circle)
                }
                
                IterationVisualization(currentStep: animationStep, totalSteps: totalSteps)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            
            // Key insight
            Text("ε₀(xₜ, t) = U-Net prediction of noise at timestep t")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .animation(.smooth(duration: 0.3), value: selectedPart)
        .animation(.smooth(duration: 0.25), value: animationStep)
        .onDisappear {
            playTask?.cancel()
            playTask = nil
            isPlaying = false
        }
    }
    
    private func togglePlay() {
        if isPlaying {
            playTask?.cancel()
            playTask = nil
            isPlaying = false
            return
        }
        isPlaying = true
        playTask = Task { @MainActor in
            while !Task.isCancelled {
                onAdvanceAnimation()
                try? await Task.sleep(for: .milliseconds(450))
            }
        }
        Task {
            await playTask?.value
            await MainActor.run {
                playTask = nil
                isPlaying = false
            }
        }
    }
}


// MARK: - Reverse noise -> image blend

private struct ReverseBlendVisualization: View {
    let currentStep: Int
    let totalSteps: Int
    
    private var noiseAmount: Double {
        max(0, 1 - Double(currentStep) / Double(max(1, totalSteps)))
    }
    
    private var signalAmount: Double {
        min(1, Double(currentStep) / Double(max(1, totalSteps)))
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Noise → image at current step")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height) * 0.88
                let cx = geo.size.width / 2
                let cy = geo.size.height / 2
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.5), .purple.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .opacity(signalAmount)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(.purple.opacity(0.5), lineWidth: 2)
                        )
                        .position(x: cx, y: cy)
                    
                    ReverseNoiseOverlay(amount: noiseAmount)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .position(x: cx, y: cy)
                }
            }
        }
    }
}

private struct ReverseNoiseOverlay: View {
    let amount: Double
    
    private static let seed = 99
    private static var positions: [(x: CGFloat, y: CGFloat, r: CGFloat)] = {
        var g = SeededRandom(seed: seed)
        return (0..<100).map { _ in
            (x: CGFloat(g.next()), y: CGFloat(g.next()), r: CGFloat(0.5 + g.next() * 1.2))
        }
    }()
    
    var body: some View {
        GeometryReader { geo in
            let n = Int(amount * Double(Self.positions.count))
            let opacity = 0.2 + amount * 0.6
            ZStack {
                ForEach(0..<min(n, Self.positions.count), id: \.self) { i in
                    let p = Self.positions[i]
                    Circle()
                        .fill(.red.opacity(opacity))
                        .frame(width: 2 * p.r, height: 2 * p.r)
                        .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                }
            }
        }
    }
}

// MARK: - Denoising path graph (noise level vs step)

private struct ReversePathGraph: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Noise level along reverse path")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Canvas { context, size in
                let padding: CGFloat = 24
                let w = size.width - 2 * padding
                let h = size.height - 2 * padding
                
                let path = Path { p in
                    p.move(to: CGPoint(x: padding, y: size.height - padding))
                    p.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding))
                    p.move(to: CGPoint(x: padding, y: size.height - padding))
                    p.addLine(to: CGPoint(x: padding, y: padding))
                }
                context.stroke(path, with: .color(.secondary.opacity(0.4)), lineWidth: 1)
                
                var curve = Path()
                let steps = 50
                for i in 0...steps {
                    let step = Double(i) / Double(steps) * Double(totalSteps)
                    let noise = max(0, 1 - step / Double(totalSteps))
                    let x = padding + CGFloat(step / Double(totalSteps)) * w
                    let y = size.height - padding - CGFloat(noise) * h
                    if i == 0 { curve.move(to: CGPoint(x: x, y: y)) }
                    else { curve.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(curve, with: .color(.purple), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                
                let currentX = padding + CGFloat(Double(currentStep) / Double(max(1, totalSteps))) * w
                let vert = Path { p in
                    p.move(to: CGPoint(x: currentX, y: size.height - padding))
                    p.addLine(to: CGPoint(x: currentX, y: padding))
                }
                context.stroke(vert, with: .color(.indigo.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                
                let dotY = size.height - padding - CGFloat(max(0, 1 - Double(currentStep) / Double(max(1, totalSteps)))) * h
                let r: CGFloat = 5
                let rect = CGRect(x: currentX - r, y: dotY - r, width: 2 * r, height: 2 * r)
                context.fill(Circle().path(in: rect), with: .color(.indigo))
                context.stroke(Circle().path(in: rect), with: .color(.white), lineWidth: 1)
            }
        }
    }
}

private struct ReversePartButton: View {
    let text: String
    let part: ReverseEquationPart
    @Binding var selectedPart: ReverseEquationPart?
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

private struct ReverseExplanationBox: View {
    let part: ReverseEquationPart
    
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

private struct IterationVisualization: View {
    let currentStep: Int
    let totalSteps: Int
    
    private func circleSize(for step: Int) -> CGFloat {
        step == currentStep ? 16 : 10
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.purple : Color.secondary.opacity(0.3))
                        .frame(width: circleSize(for: step), height: circleSize(for: step))
                        .overlay {
                            if step == currentStep {
                                Circle()
                                    .stroke(Color.purple, lineWidth: 2)
                                    .scaleEffect(1.6)
                                    .opacity(0.6)
                            }
                        }
                        .animation(.smooth(duration: 0.2), value: currentStep)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? Color.purple : Color.secondary.opacity(0.3))
                            .frame(width: 10, height: 2)
                            .animation(.smooth(duration: 0.2), value: currentStep)
                    }
                }
            }
            
            HStack(alignment: .center, spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Group {
                        if step == 0 {
                            Text("xₜ")
                                .font(.system(size: 17, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(width: circleSize(for: step), height: 22, alignment: .center)
                        } else if step == totalSteps - 1 {
                            Text("x₀")
                                .font(.system(size: 17, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(width: circleSize(for: step), height: 22, alignment: .center)
                        } else {
                            Color.clear
                                .frame(width: circleSize(for: step), height: 22)
                        }
                    }
                    
                    if step < totalSteps - 1 {
                        Color.clear
                            .frame(width: 10, height: 22)
                    }
                }
            }
        }
    }
}
