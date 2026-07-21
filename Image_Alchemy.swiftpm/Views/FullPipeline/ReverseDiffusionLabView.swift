import SwiftUI

struct ReverseDiffusionLabView: View {
    @State private var selectedSeed: Double = 1
    @State private var removedNoiseUpToStep: Int = 0  // 0 = full noise, 10 = clean
    @State private var showNoiseRow: Bool = false

    private let seedOptions: [Double] = [1, 2, 3, 4]

    private func subscriptDigits(_ value: Int) -> String {
        let map: [Character: Character] = [
            "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
            "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
        ]
        return String(String(value).compactMap { map[$0] })
    }

    var body: some View {
        GeometryReader { proxy in
            let cardSize = min(proxy.size.width * 0.55, 420)

            ZStack {
                Color.clear

                VStack(spacing: 16) {
                    Text("Reverse Diffusion")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ZStack {
                        VStack(spacing: 30) {
                            HStack(spacing: 24) {
                                VStack(spacing: 20) {
                                    NoisySeedPreviewView(
                                        selectedSeed: Int(selectedSeed),
                                        cardSize: cardSize,
                                        layersRemoved: removedNoiseUpToStep
                                    )
                                    .id(selectedSeed)
                                    .transition(.opacity)
                                    .animation(.smooth(duration: 0.4), value: selectedSeed)

                                    Text(
                                        removedNoiseUpToStep == 10
                                        ? "Clean image x₀"
                                        : "Latent x\(subscriptDigits(10 - removedNoiseUpToStep))"
                                    )
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                }

                            if removedNoiseUpToStep >= 1 {
                                VStack(spacing: 20) {
                                    PureNoiseView()
                                        .frame(width: cardSize, height: cardSize * 0.67)
                                        .clipShape(.rect(cornerRadius: 20))

                                    Text("Noise ε\(subscriptDigits(10))")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }
                            }
                            .padding(20)
                            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))

                            if showNoiseRow {
                            VStack {
                                HStack(spacing: 12) {
                                    ForEach((1...9).reversed(), id: \.self) { k in
                                        let epsilonStep = 10 - k
                                        let isAdded = removedNoiseUpToStep >= 11 - epsilonStep
                                        VStack(spacing: 8) {
                                            PureNoiseView()
                                                .frame(width: 130, height: 130)
                                                .opacity(isAdded ? 1 : 0)
                                                .offset(x: isAdded ? 0 : 14)
                                                .scaleEffect(isAdded ? 1 : 0.96)
                                                .animation(.smooth(duration: 0.85), value: isAdded)

                                            Text("Noise ε\(subscriptDigits(epsilonStep))")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                                .opacity(isAdded ? 1 : 0)
                                                .animation(.smooth(duration: 0.85), value: isAdded)
                                        }
                                    }
                                }
                            }
                            .transition(
                                .opacity
                                    .combined(with: .move(edge: .bottom))
                                    .combined(with: .scale(scale: 0.96, anchor: .top))
                            )
                            .padding(20)
                            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
                            }

                            HStack {
                                SeedArcSelectorView(
                                    selectedSeed: $selectedSeed,
                                    seedOptions: seedOptions
                                )
                            }
                        }
                    }
                    .task(id: selectedSeed) {
                        withAnimation(.smooth(duration: 0.45)) {
                            removedNoiseUpToStep = 0
                            showNoiseRow = false
                        }
                        try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))

                        try? await Task.sleep(nanoseconds: UInt64(1.2 * 1_000_000_000))

                        try? await Task.sleep(nanoseconds: UInt64(0.7 * 1_000_000_000))

                        withAnimation(.smooth(duration: 1.0)) {
                            removedNoiseUpToStep = 1
                        }
                        try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))

                        try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))

                        withAnimation(.smooth(duration: 0.8)) {
                            showNoiseRow = true
                        }
                        try? await Task.sleep(nanoseconds: UInt64(1.2 * 1_000_000_000))

                        for step in 2...10 {
                            withAnimation(.smooth(duration: 0.9)) {
                                removedNoiseUpToStep = step
                            }
                            try? await Task.sleep(nanoseconds: UInt64(1.0 * 1_000_000_000))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SeedArcSelectorView: View {
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

private struct NoisySeedPreviewView: View {
    let selectedSeed: Int
    var cardSize: CGFloat = 420
    var layersRemoved: Int = 0  // 0 = all 10 layers, 10 = clean (0 layers)

    private var visibleLayers: Int { max(0, 10 - layersRemoved) }

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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            Image(imageName(for: selectedSeed))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardSize, height: cardSize * 0.67)
                .clipped()
                .clipShape(.rect(cornerRadius: 20))

            ZStack {
                if selectedSeed == 1 {
                    ForEach(0..<visibleLayers, id: \.self) { i in
                        PureNoiseView()
                            .frame(width: cardSize, height: cardSize * 0.67)
                            .clipShape(.rect(cornerRadius: 20))
                            .opacity(0.22 + Double(i) * 0.015)
                            .animation(.smooth(duration: 0.9), value: visibleLayers)
                    }
                }
                if selectedSeed == 2 {
                    ForEach(0..<visibleLayers, id: \.self) { i in
                        PureNoiseView()
                            .frame(width: cardSize, height: cardSize * 0.67)
                            .clipShape(.rect(cornerRadius: 20))
                            .opacity(0.22 + Double(i) * 0.015)
                            .animation(.smooth(duration: 0.9), value: visibleLayers)
                    }
                }
                if selectedSeed == 3 {
                    ForEach(0..<visibleLayers, id: \.self) { i in
                        PureNoiseView()
                            .frame(width: cardSize, height: cardSize * 0.67)
                            .clipShape(.rect(cornerRadius: 20))
                            .opacity(0.22 + Double(i) * 0.015)
                            .animation(.smooth(duration: 0.9), value: visibleLayers)
                    }
                }
                if selectedSeed == 4 {
                    ForEach(0..<visibleLayers, id: \.self) { i in
                        PureNoiseView()
                            .frame(width: cardSize, height: cardSize * 0.67)
                            .clipShape(.rect(cornerRadius: 20))
                            .opacity(0.22 + Double(i) * 0.015)
                            .animation(.smooth(duration: 0.9), value: visibleLayers)
                    }
                }
            }
        }
        .frame(width: cardSize, height: cardSize * 0.67)
    }
}

#Preview {
    ReverseDiffusionLabView()
}