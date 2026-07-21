import SwiftUI

// MARK: - Full-screen Latent Feature Grid (heatmap + 3D chart)

struct ForwardDiffusionFullScreenView: View {
    @Binding var selectedIndex: Int?
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let headerHeight: CGFloat = 56
            let horizontalPadding: CGFloat = 24
            let chartMinHeight: CGFloat = 400

            let safeWidth = (geo.size.width.isFinite && geo.size.width > 0) ? geo.size.width : 400
            let safeHeight = (geo.size.height.isFinite && geo.size.height > 0) ? geo.size.height : 600
            let availableHeight = max(100, safeHeight - safeTop - safeBottom - headerHeight - 32)
            let heatmapSide = max(120, min(280, safeWidth * 0.35, availableHeight))

            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("Latent Feature Grid")
                            .font(.title2.weight(.semibold))
                        Text("2D heatmap ↔ 3D surface")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: headerHeight)
                    .padding(.top, safeTop > 0 ? 8 : 16)

                    HStack(alignment: .center, spacing: 24) {
                        LatentGridHeatmapView(selectedIndex: $selectedIndex)
                            .frame(width: heatmapSide, height: heatmapSide)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemBackground).opacity(0.9))
                                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                            )

                        LatentGridChart3DView(
                            selectedIndex: $selectedIndex,
                            onDismissFullScreen: onDismiss,
                            expandedLayout: true
                        )
                        .frame(maxWidth: .infinity, minHeight: chartMinHeight)
                        .frame(height: max(chartMinHeight, availableHeight))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemBackground).opacity(0.9))
                                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        )
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 16)
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(.container)
    }
}

