import SwiftUI

// Latent space lab: shows pixel -> latent via VAE encoder, before noise is added.
struct LatentSpaceLabView: View {
    var scale: CGFloat = 1.0
    @Binding var selectedArea: FullPipelineViewModel.LatentLabArea?
    @State private var animateFlow: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero
    @State private var currentPatchIndex: Int = 0
    @State private var showHighlights: Bool = true
    @State private var hasPlayedAnimation: Bool = false

    private let patchRows = 8
    private let patchColumns = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Centered, enlarged pipeline
                VStack(spacing: 24) {
                    HStack(alignment: .center, spacing: 24) {
                        // Original image (tap to show Training Data & VAE Encoder in bottom sheet)
                        VStack(spacing: 8) {
                            Text("Pixel Image")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            ZStack {
                                Image("OriginalImage")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                // Overlay grid + highlighted patch
                                GeometryReader { imgGeo in
                                    // Keep full width but use a shorter central band for the grid.
                                    let fullWidth = imgGeo.size.width
                                    let fullHeight = imgGeo.size.height
                                    let gridHeight = fullHeight * 0.8
                                    let topOffset = (fullHeight - gridHeight) / 2

                                    let cellWidth = fullWidth / CGFloat(patchColumns)
                                    let cellHeight = gridHeight / CGFloat(patchRows)
                                    let row = currentPatchIndex / patchColumns
                                    let col = currentPatchIndex % patchColumns

                                    ZStack {
                                        // Grid lines (compressed vertically into central band)
                                        Path { path in
                                            for r in 0...patchRows {
                                                let y = topOffset + CGFloat(r) * cellHeight
                                                path.move(to: CGPoint(x: 0, y: y))
                                                path.addLine(to: CGPoint(x: fullWidth, y: y))
                                            }
                                            for c in 0...patchColumns {
                                                let x = CGFloat(c) * cellWidth
                                                path.move(to: CGPoint(x: x, y: topOffset))
                                                path.addLine(to: CGPoint(x: x, y: topOffset + gridHeight))
                                            }
                                        }
                                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)

                                        // Highlight current patch
                                        if showHighlights {
                                            Rectangle()
                                                .stroke(Color.yellow, lineWidth: 2)
                                                .background(Color.yellow.opacity(0.15))
                                                .frame(width: cellWidth, height: cellHeight)
                                                .position(
                                                    x: cellWidth * (CGFloat(col) + 0.5),
                                                    y: topOffset + cellHeight * (CGFloat(row) + 0.5)
                                                )
                                        }
                                    }
                                }
                            }
                            .frame(width: 190, height: 160)
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                        }
                        .contentShape(.rect)
                        .onTapGesture { selectedArea = FullPipelineViewModel.LatentLabArea.pixelImage }

                        // Encoder block (node diagram) – tap to show VAE overview in bottom sheet
                        VStack(spacing: 12) {
                            Text("VAE Encoder")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            // Map current patch index to an "active" input node in the encoder diagram.
                            VAEEncoderNodeDiagram(activeInputIndex: currentPatchIndex % 6, animationStep: currentPatchIndex)
                                .frame(width: 420, height: 340)
                        }
                            .padding(10)
                            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
                            .contentShape(.rect)
                            .onTapGesture {
                                // Nil = default VAE overview in the bottom sheet.
                                selectedArea = nil
                            }

                        // Latent grid (tap to show Latent Grid details in bottom sheet)
                        VStack(spacing: 8) {
                            Text("Latent Grid")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            LatentGridPlaceholder(
                                highlightIndex: showHighlights ? currentPatchIndex : -1,
                                filledCount: currentPatchIndex + 1,
                                animationStep: currentPatchIndex
                            )
                            .frame(width: 190, height: 160)
                        }
                        .contentShape(.rect)
                        .onTapGesture { selectedArea = FullPipelineViewModel.LatentLabArea.latentGrid }
                    }
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
            // Play a single sweep across all patches once.
            if !hasPlayedAnimation {
                hasPlayedAnimation = true
                let totalPatches = max(patchRows * patchColumns, 1)
                Task { @MainActor in
                    // Wait for the encoder's initial fan‑out animation to complete
                    // before starting per‑patch animations.
                    let fanoutDurationMs: UInt64 = 2300
                    try? await Task.sleep(nanoseconds: fanoutDurationMs * 1_000_000)

                    for i in 0..<totalPatches {
                        currentPatchIndex = i
                        // First row slow and clearly visible, remaining rows moderately paced.
                        let row = i / patchColumns
                        let delayMs: UInt64 = row == 0 ? 520 : 420
                        try? await Task.sleep(nanoseconds: delayMs * 1_000_000)
                    }
                    // After the sweep completes, remove yellow markers from pixel image and latent grid.
                    showHighlights = false
                }
            }
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
        // Keep the latent lab aligned with the architecture reset button:
        // when the shared scale snaps back to the default, also smoothly reset the pan offset.
        .onChange(of: scale) { _, newScale in
            if newScale == FullPipelineViewModel.defaultArchitectureScale {
                withAnimation(.smooth(duration: 0.25)) {
                    dragOffset = .zero
                    accumulatedOffset = .zero
                }
            }
        }
    }
}
