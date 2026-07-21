import SwiftUI

struct ForwardEquationView: View {
    @Binding var timestep: Double
    @Binding var selectedPart: ForwardEquationPart?
    let signalWeight: Double
    let noiseWeight: Double
    
    var totalTimesteps: Double = 10
    var alphaBarAt: ((Double) -> Double)?
    
    @State private var isPlaying = false
    @State private var playTask: Task<Void, Never>?
    
    private func alphaBarForGraph(_ t: Double) -> Double {
        guard let alphaBarAt = alphaBarAt else {
            return max(0, 1 - t / 10)
        }
        let mappedT = t * (totalTimesteps / 10)
        return alphaBarAt(mappedT)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Interactive equation display
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Forward Diffusion Equation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 6) {
                        EquationPartButton(
                            text: "x_{t}",
                            part: .result,
                            selectedPart: $selectedPart
                        )
                        
                        ScriptText(raw: " = ", baseSize: 20)
                        
                        EquationPartButton(
                            text: "√ᾱ_{t} · x₀",
                            part: .signal,
                            selectedPart: $selectedPart
                        )
                        
                        ScriptText(raw: " + ", baseSize: 20)
                        
                        EquationPartButton(
                            text: "√(1-ᾱ_{t}) · ε",
                            part: .noise,
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
                    ExplanationBox(part: selectedPart)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
            .animation(.smooth(duration: 0.35), value: selectedPart?.rawValue)
            
            // Mini "image -> noise" blend visualization
            ForwardBlendVisualization(signalWeight: signalWeight, noiseWeight: noiseWeight)
                .frame(height: 100)
                .padding(.horizontal)
            
            // Signal vs noise curve graph
            ForwardCurveGraph(
                timestep: timestep,
                totalTimesteps: 10,
                alphaBarAt: alphaBarForGraph
            )
            .frame(height: 140)
            .padding(.horizontal)
            
            // Timestep slider + Play
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    Text("Timestep (t)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("t = \(Int(timestep))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    
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
                    .glassEffect(.regular.tint(.green).interactive(), in: .circle)
                }
                
                Slider(value: $timestep, in: 0...10, step: 1)
                    .tint(.green)
            }
            .padding(.horizontal)
            
            // Weight display
            HStack(spacing: 24) {
                WeightIndicator(label: "Signal", value: signalWeight, color: .blue)
                WeightIndicator(label: "Noise", value: noiseWeight, color: .red)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .animation(.smooth(duration: 0.3), value: selectedPart)
        .animation(.smooth(duration: 0.35), value: timestep)
        .animation(.smooth(duration: 0.35), value: signalWeight)
        .animation(.smooth(duration: 0.35), value: noiseWeight)
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
            let steps: [Double] = (0...10).map { Double($0) }
            var forward = true
            while !Task.isCancelled {
                for t in forward ? steps : steps.reversed() {
                    guard !Task.isCancelled else { return }
                    timestep = t
                    try? await Task.sleep(for: .milliseconds(400))
                }
                forward.toggle()
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

// MARK: - Forward curve graph (√ᾱ_t and √(1-ᾱ_t) vs t)

private struct ForwardCurveGraph: View {
    let timestep: Double
    let totalTimesteps: Double
    let alphaBarAt: (Double) -> Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Signal vs noise over time")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Canvas { context, size in
                let padding: CGFloat = 28
                let w = size.width - 2 * padding
                let h = size.height - 2 * padding
                
                // Axes
                let axis = Path { p in
                    p.move(to: CGPoint(x: padding, y: size.height - padding))
                    p.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding))
                    p.move(to: CGPoint(x: padding, y: size.height - padding))
                    p.addLine(to: CGPoint(x: padding, y: padding))
                }
                context.stroke(axis, with: .color(.secondary.opacity(0.4)), lineWidth: 1)
                
                // Curves: √ᾱ_t (signal) and √(1-ᾱ_t) (noise)
                let steps = 80
                var signalPath = Path()
                var noisePath = Path()
                
                for i in 0...steps {
                    let t = Double(i) / Double(steps) * totalTimesteps
                    let ab = alphaBarAt(t)
                    let sqrtAB = sqrt(max(0, ab))
                    let sqrtOneMinus = sqrt(max(0, 1 - ab))
                    
                    let x = padding + CGFloat(t / totalTimesteps) * w
                    let yBase = size.height - padding
                    let signalY = yBase - CGFloat(sqrtAB) * h
                    let noiseY = yBase - CGFloat(sqrtOneMinus) * h
                    
                    if i == 0 {
                        signalPath.move(to: CGPoint(x: x, y: signalY))
                        noisePath.move(to: CGPoint(x: x, y: noiseY))
                    } else {
                        signalPath.addLine(to: CGPoint(x: x, y: signalY))
                        noisePath.addLine(to: CGPoint(x: x, y: noiseY))
                    }
                }
                
                context.stroke(signalPath, with: .color(.blue), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                context.stroke(noisePath, with: .color(.red), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                
                // Current t indicator: vertical line + dots on both curves
                let currentX = padding + CGFloat(timestep / totalTimesteps) * w
                let vert = Path { p in
                    p.move(to: CGPoint(x: currentX, y: size.height - padding))
                    p.addLine(to: CGPoint(x: currentX, y: padding))
                }
                context.stroke(vert, with: .color(.green.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                
                let ab = alphaBarAt(timestep)
                let sqrtAB = sqrt(max(0, ab))
                let sqrtOneMinus = sqrt(max(0, 1 - ab))
                let signalY = size.height - padding - CGFloat(sqrtAB) * h
                let noiseY = size.height - padding - CGFloat(sqrtOneMinus) * h
                let dotR: CGFloat = 6
                let signalRect = CGRect(x: currentX - dotR, y: signalY - dotR, width: 2 * dotR, height: 2 * dotR)
                let noiseRect = CGRect(x: currentX - dotR, y: noiseY - dotR, width: 2 * dotR, height: 2 * dotR)
                context.fill(Circle().path(in: signalRect), with: .color(.blue))
                context.stroke(Circle().path(in: signalRect), with: .color(.white), lineWidth: 1.5)
                context.fill(Circle().path(in: noiseRect), with: .color(.red))
                context.stroke(Circle().path(in: noiseRect), with: .color(.white), lineWidth: 1.5)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    legendDot(color: .blue, label: "√ᾱₜ")
                    legendDot(color: .red, label: "√(1−ᾱₜ)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(6)
            }
        }
    }
    
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Image -> noise blend visualization

private struct ForwardBlendVisualization: View {
    let signalWeight: Double
    let noiseWeight: Double
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.7
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            
            ZStack {
                // "Image" layer (signal) – fades as t increases
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .opacity(signalWeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.blue.opacity(0.5), lineWidth: 2)
                    )
                    .position(x: cx, y: cy)
                
                // Noise layer – dots that intensify as t increases
                ForwardNoiseOverlay(amount: noiseWeight)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .position(x: cx, y: cy)
            }
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 16) {
                Text("Signal (image)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("Noise")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            .padding(.top, 4)
        }
    }
}

private struct ForwardNoiseOverlay: View {
    let amount: Double
    
    private static let seed = 42
    private static var positions: [(x: CGFloat, y: CGFloat, r: CGFloat)] = {
        var g = SeededRandom(seed: seed)
        return (0..<150).map { _ in
            (x: CGFloat(g.next()), y: CGFloat(g.next()), r: CGFloat(0.5 + g.next() * 1.5))
        }
    }()
    
    var body: some View {
        GeometryReader { geo in
            let n = Int(amount * Double(Self.positions.count))
            let opacity = 0.25 + amount * 0.6
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

private struct SeededRandom {
    private var state: UInt64
    init(seed: Int) { state = UInt64(truncatingIfNeeded: seed) }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64.max >> 11)
    }
}

// Tappable equation part button with subtle pulse when selected
private struct EquationPartButton: View {
    let text: String
    let part: ForwardEquationPart
    @Binding var selectedPart: ForwardEquationPart?
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
                baseSize: 20,
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

// Explanation box for selected equation part
private struct ExplanationBox: View {
    let part: ForwardEquationPart
    
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
                    RichText(text: part.explanation)
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

private struct WeightIndicator: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(0, CGFloat(value) * 80), height: 8)
            }
            .frame(width: 80)
            
            Text(value, format: .number.precision(.fractionLength(2)))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}
