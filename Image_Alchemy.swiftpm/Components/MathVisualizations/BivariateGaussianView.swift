import SwiftUI
import Charts

struct BivariateGaussianView: View {
    @Binding var mean: Double
    @Binding var stdDev: Double
    var expandChart: Bool = false
    var resetTrigger: Int = 0

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
    @State private var isFullScreen: Bool = false

    private func binding(
        displayAzimuth: Double,
        inclination: Double,
        autoAzimuth: Double,
        onPoseChanged: @escaping (Double, Double) -> Void
    ) -> Binding<Chart3DPose> {
        Binding(
            get: { Chart3DPose(azimuth: .degrees(displayAzimuth), inclination: .degrees(inclination)) },
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
                onPoseChanged(newAzimuth, newInclination)
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
        let item = DispatchWorkItem { self.commitDragEnded() }
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

    @ViewBuilder
    private func chartContent() -> some View {
        let interval = isUserInteracting ? dragUpdateInterval : timelineUpdateInterval
        TimelineView(.periodic(from: Date(), by: interval)) { context in
            gaussianChart(
                displayAzimuth: timeDrivenAzimuth(context.date),
                displayInclination: timeDrivenInclination(context.date),
                autoAzimuth: (context.date.timeIntervalSinceReferenceDate / revolutionPeriod).truncatingRemainder(dividingBy: 1) * 360
            )
        }
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

    private func gaussianChart(displayAzimuth: Double, displayInclination: Double, autoAzimuth: Double) -> some View {
        let m = mean
        let s = stdDev
        let coeff = 1.0 / (2 * .pi * s * s)
        let factor = 1.0 / (2 * s * s)
        return Chart3D {
            SurfacePlot(x: "x", y: "y", z: "p(x,y)") { x, y in
                let dx = x - m
                let dy = y - m
                return coeff * exp(-(dx * dx + dy * dy) * factor)
            }
            .foregroundStyle(.heightBased)
        }
        .chart3DPose(binding(displayAzimuth: displayAzimuth, inclination: displayInclination, autoAzimuth: autoAzimuth, onPoseChanged: { _, _ in }))
        .chart3DCameraProjection(.perspective)
        .id("bivariateChart")
        .animation(nil, value: mean)
        .animation(nil, value: stdDev)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in handleDragStarted(displayAzimuth: displayAzimuth) }
                .onEnded { _ in handleDragEnded() }
        )
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
        VStack(spacing: 20) {
            ZStack {
                Text("N(μ, μ, σ²)")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                if !expandChart {
                    HStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Button {
                                resetPose()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            .font(.footnote)
                            .buttonStyle(.glass)

                            Button {
                                isFullScreen = true
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                            }
                            .font(.footnote)
                            .buttonStyle(.glassProminent)
                        }
                    }
                }
            }

            Text("Bivariate Gaussian: two dimensions of latent space")
                .font(.caption)
                .foregroundStyle(.secondary)

            Group {
                if expandChart {
                    chartContent()
                        .frame(maxHeight: .infinity)
                } else {
                    chartContent()
                        .frame(height: 280)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Mean (μ)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(mean, format: .number.precision(.fractionLength(2)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $mean, in: -2...2, step: 0.2)
                        .tint(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Std Dev (σ)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(stdDev, format: .number.precision(.fractionLength(2)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $stdDev, in: 0.3...2, step: 0.1)
                        .tint(.orange)
                }
            }
            .padding(.horizontal)

            Text("Auto-revolving (pauses when dragging) • Drag to rotate • Diffusion adds correlated Gaussian noise across latent dimensions")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .fullScreenCover(isPresented: $isFullScreen) {
            BivariateGaussianFullScreenView(
                mean: $mean,
                stdDev: $stdDev,
                onDismiss: { isFullScreen = false }
            )
        }
        .onChange(of: resetTrigger) { _, _ in resetPose() }
    }
}

private struct BivariateGaussianFullScreenView: View {
    @Binding var mean: Double
    @Binding var stdDev: Double
    let onDismiss: () -> Void
    @State private var resetTrigger: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BivariateGaussianView(
                mean: $mean,
                stdDev: $stdDev,
                expandChart: true,
                resetTrigger: resetTrigger
            )

            HStack(spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        resetTrigger += 1
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.glass)

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.glassProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .padding(20)
        }
    }
}
