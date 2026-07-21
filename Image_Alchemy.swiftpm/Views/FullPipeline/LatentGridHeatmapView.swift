import SwiftUI

// MARK: - Latent grid heatmap (reused from Latent Space lab data)

struct HeatmapFeatureCallout: View {
    let label: String
    let color: Color
    /// Anchor on heatmap (0–1): where the arrow touches the grid.
    let anchor: CGPoint
    /// Direction the arrow protrudes (unit offset from anchor).
    let direction: CGPoint
    /// Direction of the straight segment after the slant (e.g. (1,0) right, (-1,0) left).
    let straightDirection: CGPoint
    /// Size of the heatmap grid (center region); full view is larger for callout margin.
    let gridSize: CGSize
    /// Origin of the grid in full view coordinates (e.g. (20,20) when grid is centered in 230x230).
    let gridOrigin: CGPoint
    /// When true, line and label animate in.
    let isRevealed: Bool

    private let arrowLength: CGFloat = 36
    private let straightLength: CGFloat = 36
    private let arrowHeadSize: CGFloat = 6

    @State private var pathProgress: CGFloat = 0
    @State private var labelOpacity: Double = 0

    var body: some View {
        let start = CGPoint(
            x: gridOrigin.x + anchor.x * gridSize.width,
            y: gridOrigin.y + anchor.y * gridSize.height
        )
        let mid = CGPoint(
            x: start.x + direction.x * arrowLength,
            y: start.y + direction.y * arrowLength
        )
        let end = CGPoint(
            x: mid.x + straightDirection.x * straightLength,
            y: mid.y + straightDirection.y * straightLength
        )
        let labelOffset = CGPoint(
            x: end.x + straightDirection.x * 6,
            y: end.y + straightDirection.y * 6
        )
        ZStack(alignment: .topLeading) {
            // Line segment (slant + straight): animate with trim
            Path { path in
                path.move(to: start)
                path.addLine(to: mid)
                path.addLine(to: end)
            }
            .trim(from: 0, to: pathProgress)
            .stroke(Color.secondary, lineWidth: 3)
            .opacity(0.95)

            // Arrowhead: visible when line is complete
            Path { path in
                let u = straightDirection
                let perp = CGPoint(x: -u.y, y: u.x)
                path.move(to: end)
                path.addLine(
                    to: CGPoint(
                        x: end.x - u.x * arrowHeadSize + perp.x * arrowHeadSize * 0.6,
                        y: end.y - u.y * arrowHeadSize + perp.y * arrowHeadSize * 0.6
                    )
                )
                path.move(to: end)
                path.addLine(
                    to: CGPoint(
                        x: end.x - u.x * arrowHeadSize - perp.x * arrowHeadSize * 0.6,
                        y: end.y - u.y * arrowHeadSize - perp.y * arrowHeadSize * 0.6
                    )
                )
            }
            .stroke(Color.secondary, lineWidth: 3)
            .opacity(pathProgress >= 1 ? 0.95 : 0)

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .glassEffect(.regular, in: .rect(cornerRadius: 6))
            .opacity(labelOpacity)
            .position(labelOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: isRevealed) { _, revealed in
            if revealed {
                withAnimation(.easeOut(duration: 0.4)) {
                    pathProgress = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        labelOpacity = 1
                    }
                }
            }
        }
        .onAppear {
            if isRevealed {
                pathProgress = 1
                labelOpacity = 1
            }
        }
    }
}

struct LatentGridHeatmapView: View {
    @Binding var selectedIndex: Int?
    @State private var revealedCalloutCount: Int = 0

    private let rows = LatentGridData.rows
    private let columns = LatentGridData.columns

    /// Feature labels and sample colors matching LatentGridData.colorForMagnitude bands.
    private static let featureCallouts: [(label: String, color: Color)] = [
        ("Sky", LatentGridData.colorForMagnitude(0.15)),
        ("Water", LatentGridData.colorForMagnitude(0.35)),
        ("Rocks", LatentGridData.colorForMagnitude(0.55)),
        ("Foliage", LatentGridData.colorForMagnitude(0.85)),
    ]

    var body: some View {
        GeometryReader { geo in
            let totalSize = geo.size
            let gridSide: CGFloat = 190
            let inset = (min(totalSize.width, totalSize.height) - gridSide) / 2
            let gridOrigin = CGPoint(x: inset, y: inset)
            let gridSize = CGSize(width: gridSide, height: gridSide)
            let cellWidth = gridSide / CGFloat(columns)
            let cellHeight = gridSide / CGFloat(rows)

            // Grid drawn in 190×190 space, then centered in the full view
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.05))
                    .frame(width: gridSide, height: gridSide)

                ForEach([Int](0..<rows), id: \.self) { row in
                    ForEach([Int](0..<columns), id: \.self) { column in
                        let index = row * columns + column
                        let magnitude = LatentGridData.sampledGrid[row][column]
                        let color = LatentGridData.colorForMagnitude(magnitude)
                        let isSelected = index == selectedIndex
                        let strokeColor = isSelected ? Color.yellow : Color.clear
                        let strokeWidth: CGFloat = isSelected ? 2 : 0

                        Rectangle()
                            .fill(color)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(strokeColor, lineWidth: strokeWidth)
                            )
                            .frame(width: cellWidth - 2, height: cellHeight - 2)
                            .position(
                                x: cellWidth * (CGFloat(column) + 0.5),
                                y: cellHeight * (CGFloat(row) + 0.5)
                            )
                            .onTapGesture {
                                selectedIndex = (selectedIndex == index) ? nil : index
                            }
                    }
                }
            }
            .frame(width: gridSide, height: gridSide)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            // .overlay(
            //     RoundedRectangle(cornerRadius: 12)
            //         .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            // )
            .frame(width: totalSize.width, height: totalSize.height)
            .position(x: totalSize.width / 2, y: totalSize.height / 2)

            .overlay(
                featureCalloutsOverlay(
                    gridSize: gridSize,
                    gridOrigin: gridOrigin,
                    revealedCount: revealedCalloutCount
                )
            )
        }
        .onAppear {
            guard revealedCalloutCount == 0 else { return }
            Task {
                for i in 1...4 {
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.35)) {
                            revealedCalloutCount = i
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func featureCalloutsOverlay(
        gridSize: CGSize,
        gridOrigin: CGPoint,
        revealedCount: Int
    ) -> some View {
        // Sky: 135° slant then horizontal right. Water & Rocks: slant down-right, horizontal right. Foliage: slant up-right, horizontal right.
        let specs: [(anchor: CGPoint, direction: CGPoint, straightDirection: CGPoint)] = [
            (CGPoint(x: 0.18, y: 0.06), CGPoint(x: 0.707, y: -0.707), CGPoint(x: 1, y: 0)),    // Sky - row 0, 135° then horizontal right
            (CGPoint(x: 0.56, y: 0.94), CGPoint(x: 0.707, y: 0.707), CGPoint(x: 1, y: 0)),      // Water - slant down-right, horizontal right
            (CGPoint(x: 0.81, y: 0.81), CGPoint(x: 0.707, y: 0.707), CGPoint(x: 1, y: 0)),      // Rocks - row 7 col 7 (1-based), slant down-right, horizontal right
            (CGPoint(x: 0.94, y: 0.31), CGPoint(x: 0.707, y: -0.707), CGPoint(x: 1, y: 0)),     // Foliage - row 3 col 8 (1-based), slant up-right, horizontal right
        ]
        ZStack {
            ForEach(Array(Self.featureCallouts.prefix(4).enumerated()), id: \.offset) { index, item in
                let spec = specs[index]
                HeatmapFeatureCallout(
                    label: item.label,
                    color: item.color,
                    anchor: spec.anchor,
                    direction: spec.direction,
                    straightDirection: spec.straightDirection,
                    gridSize: gridSize,
                    gridOrigin: gridOrigin,
                    isRevealed: index < revealedCount
                )
            }
        }
        .allowsHitTesting(false)
    }
}

