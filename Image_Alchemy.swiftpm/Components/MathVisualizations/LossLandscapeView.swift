import SwiftUI
import Charts

private func lossValue(theta1: Double, theta2: Double, ruggedness: Double) -> Double {
    let bowl = 0.25 * (theta1 * theta1 + theta2 * theta2)
    let bumps = cos(3 * theta1) * cos(3 * theta2) * 0.15 * ruggedness
    return max(0.05, bowl + bumps + 0.1)
}

// Display style for the loss landscape surface.
enum LossLandscapeStyle: String, CaseIterable {
    case heightBased = "By Height"
    case normalBased = "By Slope"
    case gradient = "Rainbow"
}

// 3D visualization of a loss landscape over parameter space.
struct LossLandscapeView: View {
    @Binding var ruggedness: Double
    @Binding var style: LossLandscapeStyle
    @Binding var usePerspective: Bool
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
            landscapeChart(
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

    private func landscapeChart(displayAzimuth: Double, displayInclination: Double, autoAzimuth: Double) -> some View {
        let r = ruggedness
        return Chart3D {
            switch style {
            case .heightBased:
                SurfacePlot(x: "θ₁", y: "θ₂", z: "L(θ)") { theta1, theta2 in
                    lossValue(theta1: theta1, theta2: theta2, ruggedness: r)
                }
                .foregroundStyle(.heightBased)
            case .normalBased:
                SurfacePlot(x: "θ₁", y: "θ₂", z: "L(θ)") { theta1, theta2 in
                    lossValue(theta1: theta1, theta2: theta2, ruggedness: r)
                }
                .foregroundStyle(.normalBased)
            case .gradient:
                SurfacePlot(x: "θ₁", y: "θ₂", z: "L(θ)") { theta1, theta2 in
                    lossValue(theta1: theta1, theta2: theta2, ruggedness: r)
                }
                .foregroundStyle(
                    EllipticalGradient(colors: [.red, .orange, .yellow, .green, .blue, .indigo, .purple])
                )
            }
        }
        .chart3DPose(binding(displayAzimuth: displayAzimuth, inclination: displayInclination, autoAzimuth: autoAzimuth, onPoseChanged: { _, _ in }))
        .chart3DCameraProjection(usePerspective ? .perspective : .orthographic)
        .id("lossLandscapeChart")
        .animation(.easeInOut(duration: 0.3), value: r)
        .animation(.easeInOut(duration: 0.25), value: style)
        .animation(.easeInOut(duration: 0.25), value: usePerspective)
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
                ScriptText(
                    raw: "L(θ) = E[ ‖ε - ε_{θ}(x_{t}, t)‖^{2} ]",
                    baseSize: 18,
                    weight: .medium
                )
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

            Text("Loss over parameter space θ - training finds the valley")
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

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Surface style")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Style", selection: $style) {
                        ForEach(LossLandscapeStyle.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Perspective (depth)", isOn: $usePerspective)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Landscape ruggedness")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(ruggedness, format: .number.precision(.fractionLength(2)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $ruggedness, in: 0...1, step: 0.1)
                        .tint(.red)
                }
            }
            .padding(.horizontal)

            Text("Auto-revolving • Drag to rotate • Gradient descent moves θ downhill toward the minimum")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .fullScreenCover(isPresented: $isFullScreen) {
            LossLandscapeFullScreenView(
                ruggedness: $ruggedness,
                style: $style,
                usePerspective: $usePerspective,
                onDismiss: { isFullScreen = false }
            )
        }
        .onChange(of: resetTrigger) { _, _ in resetPose() }
    }
}

private struct LossLandscapeFullScreenView: View {
    @Binding var ruggedness: Double
    @Binding var style: LossLandscapeStyle
    @Binding var usePerspective: Bool
    let onDismiss: () -> Void
    @State private var resetTrigger: Int = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LossLandscapeView(
                ruggedness: $ruggedness,
                style: $style,
                usePerspective: $usePerspective,
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
