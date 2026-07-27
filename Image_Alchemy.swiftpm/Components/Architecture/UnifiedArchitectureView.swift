import SwiftUI

struct UnifiedArchitectureView: View {
    let highlightedComponents: Set<UnifiedArchitectureComponent>
    let flowDirection: DiffusionFlowDirection
    let conditioningText: String
    @Binding var selectedComponent: ModelComponent
    // When true, the overview latent grid highlights the cell at `currentPatchIndex`.
    var showHighlights: Bool = false
    // Index of the current patch for the overview latent grid (0..<rows*columns).
    var currentPatchIndex: Int = 0
    // Called when the user taps a latent grid placeholder; use to e.g. expand the bottom sheet.
    var onLatentGridTap: (() -> Void)? = nil
    
    @State private var arrowSequenceStep: Int = 5
    
    init(
        highlightedComponents: Set<UnifiedArchitectureComponent>,
        flowDirection: DiffusionFlowDirection,
        conditioningText: String = "a tropical beach with white sand",
        selectedComponent: Binding<ModelComponent>,
        showHighlights: Bool = false,
        currentPatchIndex: Int = 0,
        onLatentGridTap: (() -> Void)? = nil
    ) {
        self.highlightedComponents = highlightedComponents
        self.flowDirection = flowDirection
        self.conditioningText = conditioningText
        self._selectedComponent = selectedComponent
        self.showHighlights = showHighlights
        self.currentPatchIndex = currentPatchIndex
        self.onLatentGridTap = onLatentGridTap
    }
    
    var body: some View {
        HStack(spacing: 0) {
            pixelSpaceColumn
                        
            VStack(spacing: 60) {
                ArchitectureArrow(
                    isAnimating: arrowSequenceStep == 0,
                    width: 56
                )
                                
                ArchitectureArrow(
                    isAnimating: arrowSequenceStep == 4,
                    width: 56
                )
                .rotationEffect(.degrees(180))
            }
            .padding(.horizontal, 16)
            
            latentSpaceColumn
            .offset(y: -15)
            
            VStack(spacing: 60) {
                ArchitectureArrow(
                    isAnimating: arrowSequenceStep == 1,
                    width: 56
                )
                                
                ArchitectureArrow(
                    isAnimating: arrowSequenceStep == 3,
                    width: 56
                )
                .rotationEffect(.degrees(180))
            }
            .padding(.horizontal, 16)
            
            conditioningColumn
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .task {
            await runArrowSequence()
        }
    }
    
    // MARK: - Columns
    
    private var pixelSpaceColumn: some View {
        VStack(spacing: 16) {
            // Encoder side (forward)
            VStack(alignment: .center, spacing: 16) {
                Text("Encoder Pixel Space")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                VStack(alignment: .center, spacing: 16) {
                HStack(spacing: 12) {
                    ArchitectureImageBox(
                        imageName: "OriginalImage",
                        size: CGSize(width: 80, height: 64),
                        color: .pink,
                        isActive: isActive(UnifiedArchitectureComponent.originalImage),
                        onTap: { selectedComponent = .originalImage }
                    )
                    HorizontalDataStream(
                        color: .pink,
                        isActive: isAnimatingForwardPixelToLatent,
                        height: 4,
                        width: 32
                    )
                    .offset(x: 11)
                    ArchitectureBox(
                        component: .encoder,
                        isActive: isActive(UnifiedArchitectureComponent.encoder),
                        onTap: { selectedComponent = .encoder }
                    )
                }
                }
                .padding(12)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
            }
            
            // Decoder side (reverse)
            VStack(alignment: .center, spacing: 16) {
                Text("Decoder Pixel Space")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                VStack(alignment: .center, spacing: 16) {
                HStack(spacing: 12) {
                    ArchitectureImageBox(
                        imageName: "CreatedImage",
                        size: CGSize(width: 80, height: 64),
                        color: .pink,
                        isActive: isActive(UnifiedArchitectureComponent.generatedImage),
                        onTap: { selectedComponent = .generatedImage }
                    )
                    HorizontalDataStream(
                        color: .pink,
                        isActive: isAnimatingLatentToPixel,
                        height: 4,
                        width: 32
                    )
                    .offset(x: 11)
                    ReverseArchitectureBox(
                        component: .decoder,
                        isActive: isActive(UnifiedArchitectureComponent.decoder),
                        onTap: { selectedComponent = .decoder }
                    )
                }
                }
                .padding(12)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
            }
        }
    }
    
    private var latentSpaceColumn: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Latent Space")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 40) {
                // Forward: latent + diffusion -> noisy latent
                HStack(spacing: 12) {
                    OverviewLatentGridPlaceholder(
                        highlightIndex: -1,
                        filledCount: LatentGridData.rows * LatentGridData.columns,
                        onTap: { selectedComponent = .latent; onLatentGridTap?() }
                    )
                    .frame(width: 65, height: 55)
                    HorizontalDataStream(
                        color: .green,
                        isActive: flowDirection == .forward && (isActive(UnifiedArchitectureComponent.latent) || isActive(UnifiedArchitectureComponent.diffusionProcess)),
                        height: 4,
                        width: 32
                    )
                    ArchitectureBox(
                        component: .diffusionProcess,
                        isActive: isActive(UnifiedArchitectureComponent.diffusionProcess),
                        onTap: { selectedComponent = .diffusionProcess }
                    )
                    HorizontalDataStream(
                        color: .green,
                        isActive: flowDirection == .forward && (isActive(UnifiedArchitectureComponent.diffusionProcess) || isActive(UnifiedArchitectureComponent.noisyLatent)),
                        height: 4,
                        width: 32
                    )
                    NoisyLatentNoiseBox(
                        isActive: isActive(UnifiedArchitectureComponent.noisyLatent),
                        onTap: { selectedComponent = .noisyLatent }
                    )
                }
                
                // Reverse: noisy latent + U‑Net -> clean latent
                HStack(spacing: 12) {
                    OverviewLatentGridPlaceholder(
                        highlightIndex: showHighlights ? currentPatchIndex : -1,
                        filledCount: max(currentPatchIndex + 1, LatentGridData.rows * LatentGridData.columns),
                        sampleTransform: { row, col in (row, LatentGridData.columns - 1 - col) },
                        onTap: { selectedComponent = .latent; onLatentGridTap?() }
                    )
                    .hueRotation(.degrees(25))
                    .frame(width: 65, height: 55)
                    HorizontalDataStream(
                        color: .green,
                        isActive: flowDirection == .reverse && (isActive(UnifiedArchitectureComponent.noisyLatent) || isActive(UnifiedArchitectureComponent.unetDenoiser)),
                        height: 4,
                        width: 32
                    )
                    ReverseArchitectureBox(
                        component: .unetDenoiser,
                        isActive: isActive(UnifiedArchitectureComponent.unetDenoiser),
                        onTap: { selectedComponent = .unetDenoiser },
                        widthOverride: 110
                    )
                    HorizontalDataStream(
                        color: .green,
                        isActive: flowDirection == .reverse && (isActive(UnifiedArchitectureComponent.unetDenoiser) || isActive(UnifiedArchitectureComponent.cleanLatent)),
                        height: 4,
                        width: 32
                    )
                    NoisyLatentNoiseBox(
                        isActive: isActive(UnifiedArchitectureComponent.noisyLatent),
                        onTap: { selectedComponent = .noisyLatent }
                    )
                }
                // .offset(x: 5)
            }
            .padding(12)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
        }
    }
    
    private var conditioningColumn: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Conditioning")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            VStack(alignment: .center, spacing: 25) {
                ConditioningBox(
                    promptText: conditioningText,
                    isActive: isActive(UnifiedArchitectureComponent.conditioning)
                )
                ArchitectureArrow(
                    isAnimating: arrowSequenceStep == 2,
                    width: 30
                )
                .rotationEffect(.degrees(90))
                .offset(y: 10)
                ReverseArchitectureBox(
                    component: .conditioning,
                    isActive: isActive(UnifiedArchitectureComponent.conditioning),
                    onTap: { selectedComponent = .conditioning }
                )
            }
            .padding(12)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
        }
    }
    
    private func runArrowSequence() async {
        let offStep = 5
        while true {
            for step in 0..<5 {
                await MainActor.run {
                    arrowSequenceStep = step
                }
                try? await Task.sleep(nanoseconds: 800_000_000)
                
                await MainActor.run {
                    arrowSequenceStep = offStep
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func isActive(_ component: UnifiedArchitectureComponent) -> Bool {
        highlightedComponents.contains(component)
    }
    
    private func isActive(_ component: ArchitectureComponent) -> Bool {
        isActive(UnifiedArchitectureComponent.from(component))
    }
    
    private func isActive(_ component: ReverseArchitectureComponent) -> Bool {
        isActive(UnifiedArchitectureComponent.from(component))
    }
    
    private var isAnimatingForwardPixelToLatent: Bool {
        flowDirection == .forward &&
        (isActive(UnifiedArchitectureComponent.originalImage) ||
         isActive(UnifiedArchitectureComponent.encoder) ||
         isActive(UnifiedArchitectureComponent.latent) ||
         isActive(UnifiedArchitectureComponent.diffusionProcess))
    }
    
    private var isAnimatingLatentToPixel: Bool {
        flowDirection == .reverse &&
        (isActive(UnifiedArchitectureComponent.cleanLatent) ||
         isActive(UnifiedArchitectureComponent.decoder) ||
         isActive(UnifiedArchitectureComponent.generatedImage))
    }
}

// MARK: - Overview Latent Grid (Architecture)

// Compact latent grid used inside the unified architecture diagram.
// Mirrors `LatentGridPlaceholder` from the Latent Space lab, but in a smaller, simplified card.
struct OverviewLatentGridPlaceholder: View {
    let highlightIndex: Int
    // Number of "encoded" positions; tiles fill in progressively as encoding proceeds.
    let filledCount: Int
    // Optional transform (row, col) -> (srcRow, srcCol) for sampling; nil uses identity.
    var sampleTransform: ((Int, Int) -> (Int, Int))?
    // When set, the grid is tappable (e.g. to show bottom sheet content).
    var onTap: (() -> Void)? = nil
    
    private let rows = LatentGridData.rows
    private let columns = LatentGridData.columns
    
    init(
        highlightIndex: Int,
        filledCount: Int,
        sampleTransform: ((Int, Int) -> (Int, Int))? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.highlightIndex = highlightIndex
        self.filledCount = filledCount
        self.sampleTransform = sampleTransform
        self.onTap = onTap
    }
    
    var body: some View {
        let content = gridContent
        if let onTap = onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
    
    private var gridContent: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width / CGFloat(columns)
            let cellHeight = geo.size.height / CGFloat(rows)
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green.opacity(0.05))
                
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        let isFilled = index < filledCount
                        let (srcRow, srcCol) = sampleTransform?(row, column) ?? (row, column)
                        let magnitude = LatentGridData.sampledGrid[srcRow][srcCol]
                        
                        let baseColor = LatentGridData.colorForMagnitude(magnitude)
                        let tileColor = !isFilled
                            ? Color.clear
                            : (index == highlightIndex ? Color.yellow : baseColor)
                        
                        Rectangle()
                            .fill(tileColor)
                            .frame(width: cellWidth - 1.5, height: cellHeight - 1.5)
                            .position(
                                x: cellWidth * (CGFloat(column) + 0.5),
                                y: cellHeight * (CGFloat(row) + 0.5)
                            )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .glassEffect(.clear, in: .rect(cornerRadius: 10))
        }
    }
}

// MARK: - Noisy Latent Noise (Architecture)

// Renders pure Gaussian noise for the noisy latent node in the architecture diagram.
// Duplicated from ForwardDiffusionLabView.PureNoiseView for use in UnifiedArchitectureView.
struct OverviewNoiseView: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, canvasSize in
                let rect = CGRect(origin: .zero, size: CGSize(width: canvasSize.width, height: canvasSize.height))
                let fullW = Int(canvasSize.width.rounded(.up))
                let fullH = Int(canvasSize.height.rounded(.up))
                let width = max(1, fullW - 8)
                let height = max(1, fullH - 6)
                guard let cgImage = Self.makeGaussianNoiseImage(width: width, height: height) else {
                    return
                }
                let image = Image(decorative: cgImage, scale: 1, orientation: .up)
                context.draw(image, in: rect)
            }
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private static func makeGaussianNoiseImage(width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        guard let data = ctx.data else { return nil }
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        let mean: Float = 0.5
        let std: Float = 0.25

        for i in 0..<(width * height) {
            let zR = sampleStandardNormal()
            let zG = sampleStandardNormal()
            let zB = sampleStandardNormal()
            let vR = min(max(mean + std * zR, 0), 1)
            let vG = min(max(mean + std * zG, 0), 1)
            let vB = min(max(mean + std * zB, 0), 1)
            let offset = i * bytesPerPixel
            buffer[offset + 0] = UInt8(vR * 255)
            buffer[offset + 1] = UInt8(vG * 255)
            buffer[offset + 2] = UInt8(vB * 255)
            buffer[offset + 3] = 255
        }
        return ctx.makeImage()
    }

    private static func sampleStandardNormal() -> Float {
        let u1 = max(Float.random(in: 0..<1), .leastNonzeroMagnitude)
        let u2 = Float.random(in: 0..<1)
        let r = sqrt(-2 * log(u1))
        let theta = 2 * Float.pi * u2
        return r * cos(theta)
    }
}

// Tappable noisy-latent node in the architecture diagram: shows OverviewNoiseView with active state.
struct NoisyLatentNoiseBox: View {
    let isActive: Bool
    var onTap: (() -> Void)? = nil

    @State private var glowAnimation = false
    private let boxColor = Color.green

    var body: some View {
        let content = OverviewNoiseView()
            .frame(width: 65, height: 55)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(boxColor.opacity(0.1))
            )
            .shadow(color: isActive ? boxColor.opacity(0.5) : .clear, radius: glowAnimation ? 10 : 5)
            .scaleEffect(isActive ? (glowAnimation ? 1.04 : 1.02) : 1.0)
            .animation(.smooth(duration: 0.9).repeatForever(autoreverses: true), value: glowAnimation)
            .onChange(of: isActive) { _, newValue in glowAnimation = newValue }
            .onAppear { if isActive { glowAnimation = true } }

        if let onTap = onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}
