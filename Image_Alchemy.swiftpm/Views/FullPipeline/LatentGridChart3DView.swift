import SwiftUI
import Charts

// MARK: - Chart3D of latent grid (row, col -> height = magnitude)
// Auto-revolution adapted from BivariateGaussianView: chart rotates when idle, pauses when dragging.

struct LatentGridChart3DView: View {
    @Binding var selectedIndex: Int?
    var onFullScreen: (() -> Void)? = nil
    var onDismissFullScreen: (() -> Void)? = nil
    var expandedLayout: Bool = false

    // Same 64 points as heatmap: id = row*8+col, x=col, y=row, z=sampledGrid[row][col].
    private var data: [LatentGridData.GridPoint3D] { LatentGridData.chartData }

    private let revolutionPeriod: Double = 12
    private let dragEndDebounce: Double = 0.4
    private let timelineUpdateInterval: Double = 1.0 / 30.0
    private let dragUpdateInterval: Double = 1.0 / 60.0

    @State private var userAzimuthOffset: Double = 35
    @State private var userInclination: Double = 25
    @State private var frozenAutoAzimuth: Double = 35
    @State private var isUserInteracting: Bool = false
    @State private var revolutionStartTime: Date?
    @State private var revolutionStartAzimuth: Double = 0
    @State private var debounceWorkItem: DispatchWorkItem?
    @State private var dragGestureActive: Bool = false

    private func poseBinding(
        displayAzimuth: Double,
        inclination: Double,
        autoAzimuth: Double
    ) -> Binding<Chart3DPose> {
        Binding(
            get: {
                Chart3DPose(
                    azimuth: .degrees(displayAzimuth),
                    inclination: .degrees(inclination)
                )
            },
            set: { newPose in
                guard dragGestureActive else { return }
                let newAzimuth = newPose.azimuth.degrees
                let newInclination = newPose.inclination.degrees
                if !isUserInteracting {
                    frozenAutoAzimuth = autoAzimuth
                }
                isUserInteracting = true
                userAzimuthOffset = newAzimuth - frozenAutoAzimuth
                userInclination = newInclination
            }
        )
    }

    private func handleDragStarted(displayAzimuth: Double) {
        dragGestureActive = true
        debounceWorkItem?.cancel()
        revolutionStartTime = nil
        if !isUserInteracting {
            frozenAutoAzimuth = displayAzimuth - userAzimuthOffset
        }
        isUserInteracting = true
    }

    private func handleDragEnded() {
        guard isUserInteracting else { return }
        debounceWorkItem?.cancel()
        let item = DispatchWorkItem { commitDragEnded() }
        debounceWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + dragEndDebounce, execute: item)
    }

    private func commitDragEnded() {
        guard isUserInteracting else { return }
        dragGestureActive = false
        isUserInteracting = false
        revolutionStartAzimuth = frozenAutoAzimuth + userAzimuthOffset
        revolutionStartTime = Date()
    }

    private func timeDrivenAzimuth(_ date: Date) -> Double {
        if isUserInteracting {
            return frozenAutoAzimuth + userAzimuthOffset
        }
        let elapsed = date.timeIntervalSinceReferenceDate
        if let start = revolutionStartTime {
            let sinceStart = date.timeIntervalSince(start)
            let delta = (sinceStart / revolutionPeriod).truncatingRemainder(dividingBy: 1) * 360
            return revolutionStartAzimuth + delta
        } else {
            return (elapsed / revolutionPeriod).truncatingRemainder(dividingBy: 1) * 360 + userAzimuthOffset
        }
    }

    private func timeDrivenInclination(_ date: Date) -> Double {
        userInclination
    }

    private func resetPose() {
        userAzimuthOffset = 35
        userInclination = 25
        frozenAutoAzimuth = 35
        revolutionStartTime = Date()
        revolutionStartAzimuth = 35
        isUserInteracting = false
        dragGestureActive = false
    }

    var body: some View {
        let captionPadding: CGFloat = expandedLayout ? 20 : 12
        let buttonPadding: CGFloat = expandedLayout ? 16 : 8

        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                let interval = isUserInteracting ? dragUpdateInterval : timelineUpdateInterval
                TimelineView(.periodic(from: Date(), by: interval)) { context in
                    latentChart(
                        displayAzimuth: timeDrivenAzimuth(context.date),
                        displayInclination: timeDrivenInclination(context.date),
                        autoAzimuth: (context.date.timeIntervalSinceReferenceDate / revolutionPeriod)
                            .truncatingRemainder(dividingBy: 1) * 360
                    )
                }
                .frame(minHeight: 300)
            }

            Text("Tap a heatmap cell to see it highlighted here.")
                .font(expandedLayout ? .caption : .caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(expandedLayout ? .center : .leading)
                .padding(.horizontal, 4)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: expandedLayout ? .bottom : .bottomLeading
                )
                .padding(captionPadding)

            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        resetPose()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(expandedLayout ? .subheadline : .footnote)
                }
                .buttonStyle(.glass)

                if let onFullScreen {
                    Button {
                        onFullScreen()
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(expandedLayout ? .subheadline : .footnote)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                    }
                    .glassEffect(.regular.tint(.blue).interactive(), in: .capsule)
                }

                if let onDismissFullScreen {
                    Button {
                        onDismissFullScreen()
                    } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(expandedLayout ? .subheadline : .footnote)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .padding(buttonPadding)
        }
    }

    @ViewBuilder
    private func latentChart(
        displayAzimuth: Double,
        displayInclination: Double,
        autoAzimuth: Double
    ) -> some View {
        Chart3D(data) { point in
            let isSelected = point.id == selectedIndex
            let color: Color = isSelected
                ? .yellow
                : LatentGridData.colorForMagnitude(point.z).opacity(0.9)

            PointMark(
                x: .value("col", point.x),
                y: .value("row", point.y),
                z: .value("z", point.z)
            )
            .foregroundStyle(color)
        }
        .chart3DPose(
            poseBinding(
                displayAzimuth: displayAzimuth,
                inclination: displayInclination,
                autoAzimuth: autoAzimuth
            )
        )
        .chart3DCameraProjection(.perspective)
        .chartXAxisLabel("Grid column")
        .chartYAxisLabel("Grid row")
        .chartZAxisLabel("Feature strength")
        .chartXScale(domain: -0.5...7.5, range: -0.5...0.5)
        .chartYScale(domain: -0.5...7.5, range: -0.5...0.5)
        .chartZScale(domain: 0...1, range: -0.5...0.5)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in handleDragStarted(displayAzimuth: displayAzimuth) }
                .onEnded { _ in handleDragEnded() }
        )
    }
}

