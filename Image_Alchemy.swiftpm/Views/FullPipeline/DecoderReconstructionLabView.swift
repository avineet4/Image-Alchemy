import SwiftUI

// Decoder lab: shows latent -> pixel via VAE decoder, after denoising is complete.
struct DecoderReconstructionLabView: View {
    var scale: CGFloat = 1.0
    var onSelectLatentPanel: (() -> Void)? = nil
    var onSelectImagePanel: (() -> Void)? = nil
    var onSelectDecoderPanel: (() -> Void)? = nil

    @State private var animateFlow: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero
    @State private var currentPatchIndex: Int = 0
    @State private var showHighlights: Bool = true
    @State private var hasPlayedAnimation: Bool = false
    @State private var selectedSeed: Double = 1
    @State private var decoderIntroCompleted: Bool = false

    private let patchRows = 8
    private let patchColumns = 8
    private let seedOptions: [Double] = [1, 2, 3, 4]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing: 5) {
                    HStack(alignment: .center, spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Final Latent Grid")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            latentGridPlaceholderForSeed(
                                highlightIndex: showHighlights ? currentPatchIndex : -1,
                                filledCount: currentPatchIndex + 1,
                                animationStep: currentPatchIndex
                            )
                            .frame(width: 190, height: 160)
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            onSelectLatentPanel?()
                        }

                        VStack(spacing: 12) {
                            Text("VAE Decoder")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            VAEDecoderNodeDiagram(
                                activeLatentIndex: currentPatchIndex % 4,
                                animationStep: currentPatchIndex,
                                onInitialAnimationsComplete: {
                                    decoderIntroCompleted = true
                                }
                            )
                            .frame(width: 420, height: 340)
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            onSelectDecoderPanel?()
                        }
                        .padding(10)
                        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))

                        VStack(spacing: 8) {
                            Text("Reconstructed Image")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)

                            GeometryReader { imgGeo in
                                let fullWidth = imgGeo.size.width
                                let fullHeight = imgGeo.size.height

                                // Tile geometry for mask (slightly reduced height)
                                let tileWidth = fullWidth / CGFloat(patchColumns)
                                let tileHeight = (fullHeight * 0.8) / CGFloat(patchRows)

                                // Compressed grid band (e.g. 80% height, centered)
                                let gridHeight = fullHeight * 0.8
                                let topOffset = (fullHeight - gridHeight) / 2
                                let gridCellHeight = gridHeight / CGFloat(patchRows)

                                let activeRow = currentPatchIndex / patchColumns
                                let activeCol = currentPatchIndex % patchColumns

                                ZStack {
                                    // Base image, revealed tile-by-tile using a mask
                                    Image(imageName(for: Int(selectedSeed)))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .mask(
                                            Canvas { context, _ in
                                                var path = Path()
                                                for row in 0..<patchRows {
                                                    for col in 0..<patchColumns {
                                                        let index = row * patchColumns + col
                                                        if index <= currentPatchIndex {
                                                            let rect = CGRect(
                                                                x: tileWidth * CGFloat(col),
                                                                y: tileHeight * CGFloat(row),
                                                                width: tileWidth,
                                                                height: tileHeight
                                                            )
                                                            path.addRect(rect)
                                                        }
                                                    }
                                                }
                                                context.fill(path, with: .color(.white))
                                            }
                                        )

                                    // Grid lines (compressed vertically)
                                    Path { path in
                                        for r in 0...patchRows {
                                            let y = topOffset + CGFloat(r) * gridCellHeight
                                            path.move(to: CGPoint(x: 0, y: y))
                                            path.addLine(to: CGPoint(x: fullWidth, y: y))
                                        }
                                        for c in 0...patchColumns {
                                            let x = CGFloat(c) * tileWidth
                                            path.move(to: CGPoint(x: x, y: topOffset))
                                            path.addLine(to: CGPoint(x: x, y: topOffset + gridHeight))
                                        }
                                    }
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)

                                    // Highlight current reconstructed block (aligned to compressed grid)
                                    if showHighlights {
                                        Rectangle()
                                            .stroke(Color.green, lineWidth: 2)
                                            .background(Color.green.opacity(0.15))
                                            .frame(width: tileWidth, height: gridCellHeight)
                                            .position(
                                                x: tileWidth * (CGFloat(activeCol) + 0.5),
                                                y: topOffset + gridCellHeight * (CGFloat(activeRow) + 0.5)
                                            )
                                    }
                                }
                            }
                            .frame(width: 190, height: 160)
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            onSelectImagePanel?()
                        }
                    }

                    HStack {
                        DecoderSeedArcSelectorView(
                            selectedSeed: $selectedSeed,
                            seedOptions: seedOptions
                        )
                    }
                    .scaleEffect(0.77)
                }
                .scaleEffect(scale)
                .padding()
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .offset(dragOffset)
            }
        }
        .padding(.top, 24)
        .onAppear {
            animateFlow = true
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = CGSize(
                        width: accumulatedOffset.width + value.translation.width,
                        height: accumulatedOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    accumulatedOffset = dragOffset
                }
        )
        .onChange(of: scale) { _, newScale in
            if newScale == FullPipelineViewModel.defaultArchitectureScale {
                withAnimation(.smooth(duration: 0.25)) {
                    dragOffset = .zero
                    accumulatedOffset = .zero
                }
            }
        }
        .onChange(of: decoderIntroCompleted) { _, newValue in
            guard newValue, !hasPlayedAnimation else { return }
            hasPlayedAnimation = true
            let totalPatches = max(patchRows * patchColumns, 1)
            Task { @MainActor in
                let warmupMs: UInt64 = 800
                try? await Task.sleep(nanoseconds: warmupMs * 1_000_000)

                for i in 0..<totalPatches {
                    currentPatchIndex = i
                    let row = i / patchColumns
                    let delayMs: UInt64 = row == 0 ? 520 : 420
                    try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
                }
                showHighlights = false
            }
        }
    }

    @ViewBuilder
    private func latentGridPlaceholderForSeed(highlightIndex: Int, filledCount: Int, animationStep: Int = 0) -> some View {
        let adjustedFilled = filledCountForCurrentSeed(baseFilled: filledCount)

        let rows = LatentGridData.rows
        let columns = LatentGridData.columns

        switch Int(selectedSeed) {
        case 2:
            // Seed 2: emphasize left side of the grid by mirroring
            // the sampled magnitudes horizontally.
            DecoderLatentGridPlaceholder(
                highlightIndex: highlightIndex,
                filledCount: adjustedFilled,
                animationStep: animationStep,
                sampleTransform: { row, col in
                    (row, columns - 1 - col)
                }
            )
            .hueRotation(.degrees(25))
        case 3:
            // Seed 3: rotate the latent pattern so high‑magnitude band
            // runs more vertically, roughly matching the cloud banding.
            DecoderLatentGridPlaceholder(
                highlightIndex: highlightIndex,
                filledCount: adjustedFilled,
                animationStep: animationStep,
                sampleTransform: { row, col in
                    (col, rows - 1 - row)
                }
            )
            .hueRotation(.degrees(-20))
        case 4:
            // Seed 4: mirrored and gently shifted pattern for a slightly
            // different vertical emphasis vs the default.
            DecoderLatentGridPlaceholder(
                highlightIndex: highlightIndex,
                filledCount: adjustedFilled,
                animationStep: animationStep,
                sampleTransform: { row, col in
                    // Vertical mirror around the center so the dominant
                    // band appears in a different vertical region.
                    return (rows - 1 - row, col)
                }
            )
            .hueRotation(.degrees(45))
        default:
            // Default CreatedImage: use original latent grid layout.
            DecoderLatentGridPlaceholder(
                highlightIndex: highlightIndex,
                filledCount: adjustedFilled,
                animationStep: animationStep
            )
        }
    }

    private func filledCountForCurrentSeed(baseFilled: Int) -> Int {
        let maxTiles = LatentGridData.rows * LatentGridData.columns
        // Always allow the grid to fully complete (all 64 tiles),
        // regardless of which seed image is selected. Visual
        // differences between seeds come from color/hue, not from
        // leaving part of the grid empty at the end.
        return min(baseFilled, maxTiles)
    }

    private func imageName(for seed: Int) -> String {
        switch seed {
        case 1:
            return "CreatedImage"
        case 2:
            return "seed2"
        case 3:
            return "seed3"
        case 4:
            return "seed4"
        default:
            return "CreatedImage"
        }
    }
}

private struct DecoderLatentGridPlaceholder: View {
    let highlightIndex: Int
    let filledCount: Int
    var animationStep: Int = 0
    let sampleTransform: (Int, Int) -> (Int, Int)

    init(
        highlightIndex: Int,
        filledCount: Int,
        animationStep: Int = 0,
        sampleTransform: @escaping (Int, Int) -> (Int, Int) = { row, col in (row, col) }
    ) {
        self.highlightIndex = highlightIndex
        self.filledCount = filledCount
        self.animationStep = animationStep
        self.sampleTransform = sampleTransform
    }

    private let rows = LatentGridData.rows
    private let columns = LatentGridData.columns

    // Duration multiplier: after every 8 steps, animations get faster (smaller = faster).
    private var animationDurationMultiplier: Double {
        let tier = animationStep / 8
        return 1.0 / (1.0 + Double(tier) * 0.35)
    }

    var body: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width / CGFloat(columns)
            let cellHeight = geo.size.height / CGFloat(rows)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.06))

                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        let index = row * columns + column
                        let isFilled = index < filledCount

                        let (srcRow, srcCol) = sampleTransform(row, column)
                        let magnitude = LatentGridData.sampledGrid[srcRow][srcCol]

                        let baseColor = LatentGridData.colorForMagnitude(magnitude)
                        let tileColor = !isFilled
                            ? Color.clear
                            : (index == highlightIndex ? Color.yellow : baseColor)

                        Rectangle()
                            .fill(tileColor)
                            .frame(width: cellWidth - 2, height: cellHeight - 2)
                            .position(
                                x: cellWidth * (CGFloat(column) + 0.5),
                                y: cellHeight * (CGFloat(row) + 0.5)
                            )
                            .animation(.spring(response: 0.35 * animationDurationMultiplier, dampingFraction: 0.8), value: filledCount)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
        }
    }
}

private struct VAEDecoderNodeDiagram: View {
    let activeLatentIndex: Int
    var animationStep: Int = 0
    var onInitialAnimationsComplete: (() -> Void)? = nil

    private let latentCount = 4
    private let hiddenCount = 8
    private let pixelCount = 6
    private let nodeRadius: CGFloat = 12

    @State private var pathProgress: CGFloat = 1.0
    @State private var hiddenConnectProgress: [CGFloat] = Array(repeating: 1.0, count: 8)
    @State private var pixelConnectProgress: [CGFloat] = Array(repeating: 1.0, count: 6)
    @State private var fanoutCompleted: Bool = false
    @State private var hasReportedCompletion: Bool = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            let latentX = width * 0.2
            let hiddenX = width * 0.5
            let pixelX = width * 0.8

            let latentSpacing = height / CGFloat(latentCount + 1)
            let hiddenSpacing = height / CGFloat(hiddenCount + 1)
            let pixelSpacing = height / CGFloat(pixelCount + 1)

            ZStack {
                ForEach(0..<latentCount, id: \.self) { i in
                    let yLat = latentSpacing * CGFloat(i + 1)
                    ForEach(0..<hiddenCount, id: \.self) { j in
                        let yHid = hiddenSpacing * CGFloat(j + 1)
                        Path { path in
                            path.move(to: CGPoint(x: latentX, y: yLat))
                            path.addLine(to: CGPoint(x: hiddenX, y: yHid))
                        }
                        .trim(from: 0, to: hiddenConnectProgress[j])
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    }
                }

                ForEach(0..<hiddenCount, id: \.self) { j in
                    let yHid = hiddenSpacing * CGFloat(j + 1)
                    ForEach(0..<pixelCount, id: \.self) { k in
                        let yPix = pixelSpacing * CGFloat(k + 1)
                        Path { path in
                            path.move(to: CGPoint(x: hiddenX, y: yHid))
                            path.addLine(to: CGPoint(x: pixelX, y: yPix))
                        }
                        .trim(from: 0, to: pixelConnectProgress[k])
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    }
                }

                // Highlighted connections from the active latent node through the network
                if activeLatentIndex >= 0 && activeLatentIndex < latentCount {
                    let activeHiddenIndex = activeLatentIndex % hiddenCount
                    let activePixelIndex = activeLatentIndex % pixelCount

                    let yLatSingle = latentSpacing * CGFloat(activeLatentIndex + 1)
                    let yHidSingle = hiddenSpacing * CGFloat(activeHiddenIndex + 1)

                    // Highlight outgoing connections from active latent to all hidden nodes
                    ForEach(0..<hiddenCount, id: \.self) { j in
                        let yHid = hiddenSpacing * CGFloat(j + 1)
                        Path { path in
                            path.move(to: CGPoint(x: latentX + nodeRadius, y: yLatSingle))
                            path.addLine(to: CGPoint(x: hiddenX - nodeRadius, y: yHid))
                        }
                        .trim(from: 0, to: pathProgress)
                        .stroke(
                            Color.pink.opacity(j == activeHiddenIndex ? 0.95 : 0.6),
                            lineWidth: j == activeHiddenIndex ? 3 : 2
                        )
                    }

                    // Highlight outgoing connections from selected hidden to all pixel nodes
                    ForEach(0..<pixelCount, id: \.self) { k in
                        let yPix = pixelSpacing * CGFloat(k + 1)
                        Path { path in
                            path.move(to: CGPoint(x: hiddenX + nodeRadius, y: yHidSingle))
                            path.addLine(to: CGPoint(x: pixelX - nodeRadius, y: yPix))
                        }
                        .trim(from: 0, to: pathProgress)
                        .stroke(
                            Color.green.opacity(k == activePixelIndex ? 0.95 : 0.6),
                            lineWidth: k == activePixelIndex ? 3 : 2
                        )
                    }
                }

                // Latent nodes (input to decoder)
                ForEach(0..<latentCount, id: \.self) { i in
                    let y = latentSpacing * CGFloat(i + 1)
                    let isActive = (i == activeLatentIndex)
                    decoderNode(isActive: isActive, color: .cyan, activeScale: 1.12)
                        .position(x: latentX, y: y)
                }

                // Hidden feature nodes (intermediate decoded features)
                ForEach(0..<hiddenCount, id: \.self) { j in
                    let y = hiddenSpacing * CGFloat(j + 1)
                    let isActiveHidden = (j == (activeLatentIndex % hiddenCount))
                    decoderNode(isActive: isActiveHidden, color: .cyan, activeScale: 1.08)
                        .position(x: hiddenX, y: y)
                }

                // Pixel feature nodes (output)
                ForEach(0..<pixelCount, id: \.self) { k in
                    let y = pixelSpacing * CGFloat(k + 1)
                    let isActivePixel = (k == (activeLatentIndex % pixelCount))
                    decoderNode(isActive: isActivePixel, color: .cyan, activeScale: 1.08)
                        .position(x: pixelX, y: y)
                }

                // Column labels
                Text("Latent Channels")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: latentX, y: 10)
                Text("Decoded Features")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: hiddenX, y: 10)
                Text("Pixel Features")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: pixelX, y: 10)
            }
            .animation(.spring(response: 0.7 * animationDurationMultiplier, dampingFraction: 0.9), value: activeLatentIndex)
            .onAppear {
                runLayerFanoutAndInitialPath()
            }
            .onChange(of: activeLatentIndex) { _, _ in
                if fanoutCompleted {
                    animateActivePath()
                }
            }
        }
    }

    @ViewBuilder
    private func decoderNode(isActive: Bool, color: Color, activeScale: CGFloat) -> some View {
        Circle()
            .stroke(isActive ? color : color.opacity(0.5), lineWidth: 2)
            .background(
                Circle().fill(
                    isActive ? color.opacity(0.18) : Color.white
                )
            )
            .frame(width: 24, height: 24)
            .scaleEffect(isActive ? activeScale : 1.0)
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: 4, y: 2)
    }

    // Duration multiplier: after every 8 steps, animations get faster (smaller = faster).
    private var animationDurationMultiplier: Double {
        let tier = animationStep / 8
        return 1.0 / (1.0 + Double(tier) * 0.35)
    }

    private func runLayerFanoutAndInitialPath() {
        hiddenConnectProgress = Array(repeating: 0, count: hiddenCount)
        pixelConnectProgress = Array(repeating: 0, count: pixelCount)
        pathProgress = 0
        fanoutCompleted = false

        let startTime = DispatchTime.now()
        let mult = animationDurationMultiplier
        let fanInterval: Double = 0.14 * mult

        for j in 0..<hiddenCount {
            DispatchQueue.main.asyncAfter(deadline: startTime + fanInterval * Double(j)) {
                withAnimation(.easeInOut(duration: 0.45 * mult)) {
                    hiddenConnectProgress[j] = 1.0
                }
            }
        }

        let pixelBaseDelay: Double = fanInterval * Double(hiddenCount) + 0.22 * mult
        for k in 0..<pixelCount {
            DispatchQueue.main.asyncAfter(deadline: startTime + pixelBaseDelay + fanInterval * Double(k)) {
                withAnimation(.easeInOut(duration: 0.45 * mult)) {
                    pixelConnectProgress[k] = 1.0
                }
            }
        }

        let fanoutCompletionDelay = pixelBaseDelay + fanInterval * Double(pixelCount) + 0.1 * mult
        DispatchQueue.main.asyncAfter(deadline: startTime + fanoutCompletionDelay) {
            fanoutCompleted = true
            animateActivePath()
        }

        // Notify parent after the decoder's initial fan-out and path animation complete.
        let completionDelay: Double = fanoutCompletionDelay + 0.4 * mult
        DispatchQueue.main.asyncAfter(deadline: startTime + completionDelay) {
            guard !hasReportedCompletion else { return }
            hasReportedCompletion = true
            onInitialAnimationsComplete?()
        }
    }

    private func animateActivePath() {
        pathProgress = 0
        withAnimation(.easeInOut(duration: 0.4 * animationDurationMultiplier)) {
            pathProgress = 1
        }
    }
}

private struct DecoderSeedArcSelectorView: View {
    @Binding var selectedSeed: Double
    let seedOptions: [Double]

    var body: some View {
        VStack(spacing: -85) {
            ZStack {
                ArcSelector(
                    value: $selectedSeed,
                    range: 1...4,
                    presets: seedOptions,
                    showsDegreeSymbol: false
                )
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)

                Text("Seed \(Int(selectedSeed))")
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .offset(y: -20)
            }

            Text("Select starting seed")
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    DecoderReconstructionLabView()
}

