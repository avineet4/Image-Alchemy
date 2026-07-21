import SwiftUI

// Latent grid from previous step: visual 2D heatmap + 3D surface, with minimal text.
struct ForwardDiffusionLatentGridSection: View {
    var scale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero
    @State private var selectedIndex: Int? = nil
    @State private var isFullScreen: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 12) {
                // Card: centered header + side‑by‑side grid and 3D chart
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Latent Feature Grid")
                            .font(.headline.weight(.semibold))
                        Text("Explore the bridge between 2D heatmaps and 3D surfaces")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .center, spacing: 89) {
                        LatentGridHeatmapView(selectedIndex: $selectedIndex)
                            .frame(width: 185, height: 185)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemBackground).opacity(0.9))
                                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                            )
                        
                        LatentGridChart3DView(selectedIndex: $selectedIndex, onFullScreen: { isFullScreen = true })
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
                .padding(20)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
                // .background(
                //     RoundedRectangle(cornerRadius: 16)
                //         .fill(Color(.tertiarySystemBackground).opacity(0.75))
                //         .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                // )
            }
            .frame(maxWidth: min(geo.size.width - 32, 980))
            .scaleEffect(scale * 0.85)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .offset(dragOffset)
            .padding(.horizontal, 16)
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
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            ForwardDiffusionFullScreenView(selectedIndex: $selectedIndex, onDismiss: { isFullScreen = false })
        }
    }
}
#Preview {
    ForwardDiffusionLatentGridSection()
}
