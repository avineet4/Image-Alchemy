import SwiftUI

// Node‑based diagram of the VAE encoder, inspired by the Transformer FFN pipeline:
struct VAEEncoderNodeDiagram: View {
    let activeInputIndex: Int
    var animationStep: Int = 0

    private let inputCount = 6
    private let hiddenCount = 8
    private let latentCount = 4
    private let nodeRadius: CGFloat = 12
    @State private var pathProgress: CGFloat = 1.0
    @State private var hiddenConnectProgress: [CGFloat] = Array(repeating: 1.0, count: 8)
    @State private var latentConnectProgress: [CGFloat] = Array(repeating: 1.0, count: 4)
    @State private var fanoutCompleted: Bool = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            // X positions for three vertical columns
            let inputX = width * 0.2
            let hiddenX = width * 0.5
            let latentX = width * 0.8

            // Y spacing
            let inputSpacing = height / CGFloat(inputCount + 1)
            let hiddenSpacing = height / CGFloat(hiddenCount + 1)
            let latentSpacing = height / CGFloat(latentCount + 1)

            ZStack {
                ForEach(0..<inputCount, id: \.self) { i in
                    let yIn = inputSpacing * CGFloat(i + 1)
                    ForEach(0..<hiddenCount, id: \.self) { j in
                        let yHid = hiddenSpacing * CGFloat(j + 1)
                        Path { path in
                            path.move(to: CGPoint(x: inputX, y: yIn))
                            path.addLine(to: CGPoint(x: hiddenX, y: yHid))
                        }
                        .trim(from: 0, to: hiddenConnectProgress[j])
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    }
                }

                ForEach(0..<hiddenCount, id: \.self) { j in
                    let yHid = hiddenSpacing * CGFloat(j + 1)
                    ForEach(0..<latentCount, id: \.self) { k in
                        let yLat = latentSpacing * CGFloat(k + 1)
                        Path { path in
                            path.move(to: CGPoint(x: hiddenX, y: yHid))
                            path.addLine(to: CGPoint(x: latentX, y: yLat))
                        }
                        .trim(from: 0, to: latentConnectProgress[k])
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    }
                }

                // Highlighted connections from the active input through the network
                if activeInputIndex >= 0 && activeInputIndex < inputCount {
                    let activeHiddenIndex = activeInputIndex % hiddenCount
                    let activeLatentIndex = activeInputIndex % latentCount

                    let yIn = inputSpacing * CGFloat(activeInputIndex + 1)
                    let yHidSingle = hiddenSpacing * CGFloat(activeHiddenIndex + 1)

                    // Highlight all outgoing connections from the active input node to every hidden node.
                    ForEach(0..<hiddenCount, id: \.self) { j in
                        let yHid = hiddenSpacing * CGFloat(j + 1)
                        Path { path in
                            path.move(to: CGPoint(x: inputX + nodeRadius, y: yIn))
                            path.addLine(to: CGPoint(x: hiddenX - nodeRadius, y: yHid))
                        }
                        .trim(from: 0, to: pathProgress)
                        .stroke(Color.pink.opacity(j == activeHiddenIndex ? 0.95 : 0.6), lineWidth: j == activeHiddenIndex ? 3 : 2)
                    }

                    // Highlight all outgoing connections from the selected hidden node to every latent node.
                    ForEach(0..<latentCount, id: \.self) { k in
                        let yLat = latentSpacing * CGFloat(k + 1)
                        Path { path in
                            path.move(to: CGPoint(x: hiddenX + nodeRadius, y: yHidSingle))
                            path.addLine(to: CGPoint(x: latentX - nodeRadius, y: yLat))
                        }
                        .trim(from: 0, to: pathProgress)
                        .stroke(Color.green.opacity(k == activeLatentIndex ? 0.95 : 0.6), lineWidth: k == activeLatentIndex ? 3 : 2)
                    }
                }

                // Input layer nodes (pixels / patch features)
                ForEach(0..<inputCount, id: \.self) { i in
                    let y = inputSpacing * CGFloat(i + 1)
                    let isActive = (i == activeInputIndex)
                    encoderNode(isActive: isActive, color: .cyan, activeScale: 1.12)
                        .position(x: inputX, y: y)
                }

                // Hidden feature nodes
                ForEach(0..<hiddenCount, id: \.self) { j in
                    let y = hiddenSpacing * CGFloat(j + 1)
                    let isActiveHidden = (j == (activeInputIndex % hiddenCount))
                    encoderNode(isActive: isActiveHidden, color: .cyan, activeScale: 1.08)
                        .position(x: hiddenX, y: y)
                }

                // Latent feature nodes
                ForEach(0..<latentCount, id: \.self) { k in
                    let y = latentSpacing * CGFloat(k + 1)
                    let isActiveLatent = (k == (activeInputIndex % latentCount))
                    encoderNode(isActive: isActiveLatent, color: .cyan, activeScale: 1.08)
                        .position(x: latentX, y: y)
                }

                // Column labels aligned above each set of nodes
                Text("Pixel Features")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: inputX, y: 10)
                Text("Encoded Features")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: hiddenX, y: 10)
                Text("Latent Channels")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: latentX, y: 10)
            }
            .animation(.spring(response: 0.7 * animationDurationMultiplier, dampingFraction: 0.9), value: activeInputIndex)
            .onAppear {
                runLayerFanoutAndInitialPath()
            }
            .onChange(of: activeInputIndex) { _, _ in
                // Only animate per‑patch path after fan‑out has fully completed.
                if fanoutCompleted {
                    animateActivePath()
                }
            }
        }
    }

    @ViewBuilder
    private func encoderNode(isActive: Bool, color: Color, activeScale: CGFloat) -> some View {
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

    private func runLayerFanoutAndInitialPath() {
        // Reset all progress
        hiddenConnectProgress = Array(repeating: 0, count: hiddenCount)
        latentConnectProgress = Array(repeating: 0, count: latentCount)
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

        let latentBaseDelay: Double = fanInterval * Double(hiddenCount) + 0.22 * mult
        for k in 0..<latentCount {
            DispatchQueue.main.asyncAfter(deadline: startTime + latentBaseDelay + fanInterval * Double(k)) {
                withAnimation(.easeInOut(duration: 0.45 * mult)) {
                    latentConnectProgress[k] = 1.0
                }
            }
        }

        // After fan‑out is fully drawn, mark complete and play initial highlighted path.
        let fanoutCompletionDelay = latentBaseDelay + fanInterval * Double(latentCount) + 0.1 * mult
        DispatchQueue.main.asyncAfter(deadline: startTime + fanoutCompletionDelay) {
            fanoutCompleted = true
            animateActivePath()
        }
    }

    private var animationDurationMultiplier: Double {
        let tier = animationStep / 7
        return 1.0 / (1.0 + Double(tier) * 0.35)
    }

    private func animateActivePath() {
        pathProgress = 0
        withAnimation(.easeInOut(duration: 0.4 * animationDurationMultiplier)) {
            pathProgress = 1
        }
    }
}

struct LatentGridPlaceholder: View {
    let highlightIndex: Int
    let filledCount: Int
    var animationStep: Int = 0

    let rows = LatentGridData.rows
    let columns = LatentGridData.columns

    private var animationDurationMultiplier: Double {
        let tier = animationStep / 7
        return 1.0 / (1.0 + Double(tier) * 0.35)
    }

    var body: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width / CGFloat(columns)
            let cellHeight = geo.size.height / CGFloat(rows)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.06))
                ForEach([Int](0..<rows), id: \.self) { row in
                    ForEach([Int](0..<columns), id: \.self) { column in
                        let index = row * columns + column
                        let isFilled = index < filledCount
                        let magnitude = LatentGridData.sampledGrid[row][column]

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

