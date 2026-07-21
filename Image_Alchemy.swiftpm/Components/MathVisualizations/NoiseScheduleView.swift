import SwiftUI

// MARK: - Noise Schedule Equation Parts

enum NoiseScheduleEquationPart: String, CaseIterable {
    case betaT        // βₜ
    case betaMin      // βₘᵢₙ
    case betaMax      // βₘₐₓ
    case timeRatio    // t/T
    
    var title: String {
        switch self {
        case .betaT: return "Noise at Timestep t"
        case .betaMin: return "Minimum Noise"
        case .betaMax: return "Maximum Noise"
        case .timeRatio: return "Time Ratio"
        }
    }
    
    var explanation: String {
        switch self {
        case .betaT:
            return "βₜ is the noise level (variance) at timestep t. It determines how much noise is added to the image at each step of the diffusion process."
        case .betaMin:
            return "βₘᵢₙ is the minimum noise level, applied at the start (t=0). This is typically a small value like 0.0001, ensuring we start with minimal noise."
        case .betaMax:
            return "βₘₐₓ is the maximum noise level, reached at the final timestep (t=T). This is typically around 0.02, representing the maximum noise we add."
        case .timeRatio:
            return "t/T is the normalized timestep, ranging from 0 to 1. It represents how far we are through the diffusion process, controlling the interpolation between βₘᵢₙ and βₘₐₓ."
        }
    }
    
    var example: String? {
        switch self {
        case .betaT:
            return "t=0: β₀ = βₘᵢₙ\nt=T: βₜ = βₘₐₓ\nt=T/2: βₜ ≈ (βₘᵢₙ+βₘₐₓ)/2"
        case .betaMin:
            return "βₘᵢₙ = 0.0001\n(starting noise)"
        case .betaMax:
            return "βₘₐₓ = 0.02\n(maximum noise)"
        case .timeRatio:
            return "t=0: t/T = 0\nt=T/2: t/T = 0.5\nt=T: t/T = 1"
        }
    }
}

// Helper to build a Text with a subscript run.
private func makeSubscriptText(
    base: String,
    sub: String,
    baseSize: CGFloat,
    weight: Font.Weight = .regular
) -> Text {
    let baseFont = Font.system(size: baseSize, weight: weight, design: .serif)
    let subFont = Font.system(size: baseSize * 0.7, weight: weight, design: .serif)
    return Text("\(Text(base).font(baseFont))\(Text(sub).font(subFont).baselineOffset(-4))")
}

// Interactive visualization of the noise schedule
struct NoiseScheduleView: View {
    @Binding var currentTimestep: Double
    let totalTimesteps: Double
    let betaMin: Double
    let betaMax: Double
    let betaAt: (Double) -> Double
    let alphaBarAt: (Double) -> Double
    @State private var selectedPart: NoiseScheduleEquationPart?
    @State private var isPlaying = false
    @State private var playTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 20) {
            // Interactive formula display
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Linear noise schedule")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 6) {
                        NoiseSchedulePartButton(
                            text: "β_{t}",
                            part: .betaT,
                            selectedPart: $selectedPart
                        )
                        
                        ScriptText(raw: " = ", baseSize: 20)
                        
                        NoiseSchedulePartButton(
                            text: "β_{min}",
                            part: .betaMin,
                            selectedPart: $selectedPart
                        )
                        
                        ScriptText(raw: " + (", baseSize: 20)
                        
                        NoiseSchedulePartButton(
                            text: "β_{max}",
                            part: .betaMax,
                            selectedPart: $selectedPart
                        )
                        
                        ScriptText(raw: " - ", baseSize: 20)
                        
                        NoiseSchedulePartButton(
                            text: "β_{min}",
                            part: .betaMin,
                            selectedPart: $selectedPart
                        )
                        
                        ScriptText(raw: ") · ", baseSize: 20)
                        
                        NoiseSchedulePartButton(
                            text: "t/T",
                            part: .timeRatio,
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
                    NoiseScheduleExplanationBox(part: selectedPart)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
            .animation(.smooth(duration: 0.35), value: selectedPart?.rawValue)
            .padding(.horizontal)
            
            
            // Dual curve: β(t) and ᾱ(t) with tap-to-seek
            NoiseScheduleDualGraph(
                currentTimestep: currentTimestep,
                totalTimesteps: totalTimesteps,
                betaAt: betaAt,
                alphaBarAt: alphaBarAt,
                onTimestepSelected: { t in
                    withAnimation(.smooth(duration: 0.25)) {
                        currentTimestep = t
                    }
                }
            )
            .frame(height: 200)
            .padding(.horizontal)
            
            // Timestep controls: slider + play
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text("Timestep (t)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(currentTimestep)) / \(Int(totalTimesteps))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    
                    Button {
                        withAnimation(.snappy(duration: 0.15)) {
                            togglePlay()
                        }
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .glassEffect(.regular.tint(.orange).interactive(), in: .circle)
                }
                
                Slider(value: $currentTimestep, in: 0...totalTimesteps, step: 10)
                    .tint(.orange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            
            // Computed values display (animated)
            HStack(spacing: 24) {
                ValueDisplay(
                    label: makeSubscriptText(base: "β", sub: "t", baseSize: 14),
                    value: betaAt(currentTimestep),
                    color: .orange
                )
                ValueDisplay(
                    label: makeSubscriptText(base: "ᾱ", sub: "t", baseSize: 14),
                    value: alphaBarAt(currentTimestep),
                    color: .blue
                )
                ValueDisplay(
                    label: makeSubscriptText(base: "√ᾱ", sub: "t", baseSize: 14),
                    value: sqrt(alphaBarAt(currentTimestep)),
                    color: .green
                )
            }
            .padding(.horizontal)
            
            // Explanation
            RichText(text: "Linear schedule: β increases from β_{min} to β_{max} over T steps. Drag the graph to jump to a timestep.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .animation(.smooth(duration: 0.3), value: selectedPart)
        .animation(.smooth(duration: 0.28), value: currentTimestep)
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
        let total = totalTimesteps
        playTask = Task { @MainActor in
            var forward = true
            while !Task.isCancelled {
                let steps = 50
                let range = forward ? stride(from: 0.0, through: total, by: total / Double(steps)).map { $0 }
                    : stride(from: total, through: 0, by: -total / Double(steps)).map { $0 }
                for t in range {
                    guard !Task.isCancelled else { return }
                    currentTimestep = min(total, max(0, t))
                    try? await Task.sleep(for: .milliseconds(80))
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

private struct ValueDisplay: View {
    let label: Text
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            label
                .foregroundStyle(color)
            Text(value, format: .number.precision(.fractionLength(4)))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct NoiseScheduleNoiseOverlay: View {
    let amount: Double
    
    private static let seed = 88
    private static var positions: [(x: CGFloat, y: CGFloat, r: CGFloat)] = {
        var g = NoiseScheduleSeededRandom(seed: seed)
        return (0..<120).map { _ in
            (x: CGFloat(g.next()), y: CGFloat(g.next()), r: CGFloat(0.5 + g.next() * 1.2))
        }
    }()
    
    var body: some View {
        GeometryReader { geo in
            let n = Int(amount * Double(Self.positions.count))
            let opacity = 0.2 + amount * 0.65
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

private struct NoiseScheduleSeededRandom {
    private var state: UInt64
    init(seed: Int) { state = UInt64(truncatingIfNeeded: seed) }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64.max >> 11)
    }
}

// MARK: - Dual graph (β and ᾱ) with tap/drag to set timestep

private struct NoiseScheduleDualGraph: View {
    let currentTimestep: Double
    let totalTimesteps: Double
    let betaAt: (Double) -> Double
    let alphaBarAt: (Double) -> Double
    var onTimestepSelected: (Double) -> Void
    
    private let padding: CGFloat = 28
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                legendDot(color: .orange, label: "βₜ")
                legendDot(color: .blue, label: "ᾱₜ")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            
            GeometryReader { geo in
                let w = geo.size.width - 2 * padding
                
                ZStack(alignment: .topLeading) {
                    Canvas { context, size in
                        let graphW = size.width - 2 * padding
                        let graphH = size.height - 2 * padding
                        drawGraph(context: context, size: size, graphWidth: graphW, graphHeight: graphH)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x - padding
                                guard w > 0 else { return }
                                let fraction = min(1, max(0, x / w))
                                let t = fraction * totalTimesteps
                                onTimestepSelected(t)
                            }
                    )
                    .onTapGesture { location in
                        let x = location.x - padding
                        guard w > 0 else { return }
                        let fraction = min(1, max(0, x / w))
                        onTimestepSelected(fraction * totalTimesteps)
                    }
                }
            }
            .overlay(alignment: .bottomLeading) {
                Text("Drag or tap to set t")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, padding)
                    .padding(.bottom, 4)
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
    
    private func drawGraph(context: GraphicsContext, size: CGSize, graphWidth: CGFloat, graphHeight: CGFloat) {
        let width = size.width
        let height = size.height
        let maxBeta = betaAt(totalTimesteps) * 1.05
        let steps = 100
        
        // Axes
        let axisPath = Path { path in
            path.move(to: CGPoint(x: padding, y: height - padding))
            path.addLine(to: CGPoint(x: width - padding, y: height - padding))
            path.move(to: CGPoint(x: padding, y: height - padding))
            path.addLine(to: CGPoint(x: padding, y: padding))
        }
        context.stroke(axisPath, with: .color(.secondary.opacity(0.45)), lineWidth: 1)
        
        // β(t) curve and fill
        var betaPath = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps) * totalTimesteps
            let beta = betaAt(t)
            let x = padding + CGFloat(t / totalTimesteps) * graphWidth
            let y = (height - padding) - CGFloat(beta / maxBeta) * graphHeight
            if i == 0 { betaPath.move(to: CGPoint(x: x, y: y)) }
            else { betaPath.addLine(to: CGPoint(x: x, y: y)) }
        }
        var betaFill = betaPath
        betaFill.addLine(to: CGPoint(x: width - padding, y: height - padding))
        betaFill.addLine(to: CGPoint(x: padding, y: height - padding))
        betaFill.closeSubpath()
        context.fill(betaFill, with: .color(.orange.opacity(0.18)))
        context.stroke(betaPath, with: .color(.orange), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        
        // ᾱ(t) curve (same height scale 0...1)
        var alphaPath = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps) * totalTimesteps
            let ab = alphaBarAt(t)
            let x = padding + CGFloat(t / totalTimesteps) * graphWidth
            let y = (height - padding) - CGFloat(ab) * graphHeight
            if i == 0 { alphaPath.move(to: CGPoint(x: x, y: y)) }
            else { alphaPath.addLine(to: CGPoint(x: x, y: y)) }
        }
        context.stroke(alphaPath, with: .color(.blue), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        
        // Current t indicator
        let currentX = padding + CGFloat(currentTimestep / totalTimesteps) * graphWidth
        let vertPath = Path { path in
            path.move(to: CGPoint(x: currentX, y: height - padding))
            path.addLine(to: CGPoint(x: currentX, y: padding))
        }
        context.stroke(vertPath, with: .color(.purple.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        
        let currentBeta = betaAt(currentTimestep)
        let currentBetaY = (height - padding) - CGFloat(currentBeta / maxBeta) * graphHeight
        let dotR: CGFloat = 6
        let betaRect = CGRect(x: currentX - dotR, y: currentBetaY - dotR, width: 2 * dotR, height: 2 * dotR)
        context.fill(Circle().path(in: betaRect), with: .color(.orange))
        context.stroke(Circle().path(in: betaRect), with: .color(.white), lineWidth: 1.5)
        
        let currentAlpha = alphaBarAt(currentTimestep)
        let currentAlphaY = (height - padding) - CGFloat(currentAlpha) * graphHeight
        let alphaRect = CGRect(x: currentX - dotR, y: currentAlphaY - dotR, width: 2 * dotR, height: 2 * dotR)
        context.fill(Circle().path(in: alphaRect), with: .color(.blue))
        context.stroke(Circle().path(in: alphaRect), with: .color(.white), lineWidth: 1.5)
    }
}

// MARK: - Equation Part Button

private struct NoiseSchedulePartButton: View {
    let text: String
    let part: NoiseScheduleEquationPart
    @Binding var selectedPart: NoiseScheduleEquationPart?
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
            .padding(.horizontal, 8)
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

private struct NoiseScheduleExplanationBox: View {
    let part: NoiseScheduleEquationPart
    
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
