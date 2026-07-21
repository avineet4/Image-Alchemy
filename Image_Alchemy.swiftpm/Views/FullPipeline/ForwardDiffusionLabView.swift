import SwiftUI

struct ForwardDiffusionLabView: View {
    @State private var showFirstNoise: Bool = false
    @State private var mergeProgress: CGFloat = 0    // 0 = x0 only, 1 = x1 fully merged
    @State private var imageCenterProgress: CGFloat = 0  // 0 = left-shifted, 1 = centered
    @State private var showHello: Bool = false
    @State private var removedNoiseUpToStep: Int = 1 // ε₂ starts at 2
    @State private var stepMergeProgress: [CGFloat] = Array(repeating: 0, count: 11) // index by step 0...10
    
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

            VStack(spacing: 20) {

                Text("Forward Diffusion")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 24) {
                    // Left: original image x0, gradually merged with epsilon to form x1
                    VStack(spacing: 20) {
                        ZStack {
                            Image("OriginalImage")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(.rect(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.12), radius: 14, y: 6)

                            PureNoiseView()
                                .frame(width: cardSize, height: cardSize)
                                .opacity(0.5 * Double(mergeProgress))
                                .mask(
                                    GeometryReader { geo in
                                        let w = geo.size.width
                                        let h = geo.size.height
                                        let visibleW = w * mergeProgress
                                        Rectangle()
                                            .frame(width: max(0, visibleW), height: h)
                                            .position(x: visibleW / 2, y: h / 2)
                                    }
                                )
                                .frame(width: cardSize, height: cardSize * 0.67)
                                .clipShape(.rect(cornerRadius: 20))
                                .animation(.smooth(duration: 1.8), value: mergeProgress)

                            // Individual ε₂...ε₁₀ merge overlays (one per noise step)
                            ForEach(2...10, id: \.self) { step in
                                let progress = stepMergeProgress[step]
                                if progress > 0 {
                                    PureNoiseView()
                                        .frame(width: cardSize, height: cardSize)
                                        .opacity(0.35 * Double(progress))
                                        .mask(
                                            GeometryReader { geo in
                                                let w = geo.size.width
                                                let h = geo.size.height
                                                let visibleW = w * progress
                                                Rectangle()
                                                    .frame(width: max(0, visibleW), height: h)
                                                    .position(x: visibleW / 2, y: h / 2)
                                            }
                                        )
                                        .frame(width: cardSize, height: cardSize * 0.67)
                                        .clipShape(.rect(cornerRadius: 20))
                                        .animation(.smooth(duration: 0.7), value: progress)
                                }
                            }
                        }
                        .frame(width: cardSize, height: cardSize * 0.67)

                        let currentStep: Int = {
                            if mergeProgress == 0 {
                                return 0
                            } else if removedNoiseUpToStep < 2 {
                                return 1
                            } else if removedNoiseUpToStep <= 10 {
                                return removedNoiseUpToStep
                            } else {
                                return 10
                            }
                        }()

                        Text(
                            currentStep == 0
                            ? "Original image x₀"
                            : "Merged image x\(subscriptDigits(currentStep))"
                        )
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }

                    // Right: ε₁ appears after a delay, then fades out as we merge into x1
                    if showFirstNoise {
                        VStack(spacing: 20) {
                            PureNoiseView()
                                .frame(width: cardSize, height: cardSize * 0.67)
                                .opacity(1 - Double(mergeProgress))
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                    removal: .opacity.combined(with: .scale(scale: 1.04))
                                ))

                            Text("Noise ε\(subscriptDigits(1))")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                    }
                }
                .padding(20)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))

                if showHello && removedNoiseUpToStep < 10 {
                    VStack {
                        HStack(spacing: 12) {
                            ForEach(2...10, id: \.self) { step in
                                let isRemoved = step <= removedNoiseUpToStep
                                VStack(spacing: 8) {
                                    PureNoiseView()
                                        .frame(width: 130, height: 130)
                                        .opacity(isRemoved ? 0 : 1)
                                        .offset(x: isRemoved ? -14 : 0)
                                        .scaleEffect(isRemoved ? 0.96 : 1)

                                    Text("Noise ε\(subscriptDigits(step))")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .opacity(isRemoved ? 0 : 1)
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.top, 24)
        .task {
            // Delay after original image x0, before noise ε₁
            try? await Task.sleep(nanoseconds: UInt64(0.7 * 1_000_000_000))

            // 1) Delay before revealing ε₁ on the right
            try? await Task.sleep(nanoseconds: UInt64(0.9 * 1_000_000_000))
            withAnimation(.smooth(duration: 0.7)) {
                showFirstNoise = true
            }

            // 2) Pause briefly after ε₁ is fully visible
            try? await Task.sleep(nanoseconds: UInt64(0.9 * 1_000_000_000))

            // 3) Bring the original image cleanly to the exact center
            withAnimation(.smooth(duration: 0.9)) {
                imageCenterProgress = 1
            }
            try? await Task.sleep(nanoseconds: UInt64(0.9 * 1_000_000_000))

            // Extra hold before fading out ε₁
            try? await Task.sleep(nanoseconds: UInt64(0.35 * 1_000_000_000))

            // 4) Remove the right noise card before merging
            withAnimation(.smooth(duration: 0.55)) {
                showFirstNoise = false
            }

            try? await Task.sleep(nanoseconds: UInt64(0.5 * 1_000_000_000))

            // 5) Animate x0 + ε₁ -> x1 on the left (merge)
            withAnimation(.smooth(duration: 1.8)) {
                mergeProgress = 1
            }

            try? await Task.sleep(nanoseconds: UInt64(1.0 * 1_000_000_000))

            withAnimation(.smooth(duration: 0.5)) {
                showHello = true
            }

            // 7) After showing ε₂...ε₁₀, pause, then for each step:
            //    (a) run an individual overlay sweep for this ε on the main image,
            //    (b) once overlaid, fade out that ε tile from the row.
            try? await Task.sleep(nanoseconds: UInt64(0.9 * 1_000_000_000))
            for step in 2...10 {
                // (a) advance merge overlay on the main image for THIS ε step
                withAnimation(.smooth(duration: 0.7)) {
                    if step < stepMergeProgress.count {
                        stepMergeProgress[step] = 1
                    }
                }
                try? await Task.sleep(nanoseconds: UInt64(0.7 * 1_000_000_000))

                // (b) now remove this ε step from the row
                withAnimation(.smooth(duration: 0.55)) {
                    removedNoiseUpToStep = step
                }
                try? await Task.sleep(nanoseconds: UInt64(0.4 * 1_000_000_000))
            }

            // 8) Once all noise tiles are removed, fade out the entire ε-row container.
            try? await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
            withAnimation(.smooth(duration: 0.6)) {
                showHello = false
            }
        }
    }
}

struct PureNoiseView: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, canvasSize in
                let rect = CGRect(origin: .zero, size: CGSize(width: canvasSize.width, height: canvasSize.height))
                
                let width = Int(canvasSize.width.rounded(.up))
                let height = Int(canvasSize.height.rounded(.up))
                guard width > 0, height > 0,
                      let cgImage = Self.makeGaussianNoiseImage(width: width, height: height) else {
                    return
                }
                
                let image = Image(decorative: cgImage, scale: 1, orientation: .up)
                context.draw(image, in: rect)
            }
            .clipShape(.rect(cornerRadius: 20))
            // .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        }
    }

    private static func makeGaussianNoiseImage(width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        guard let data = ctx.data else { return nil }
        let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        // ε ~ N(0, 1), mapped to [0,1] via mean 0.5, std 0.25 (clipped)
        let mean: Float = 0.5
        let std: Float = 0.25

        for i in 0..<(width * height) {
            // Independent Gaussian samples per channel
            let zR = sampleStandardNormal()
            let zG = sampleStandardNormal()
            let zB = sampleStandardNormal()

            let vR = min(max(mean + std * zR, 0), 1)
            let vG = min(max(mean + std * zG, 0), 1)
            let vB = min(max(mean + std * zB, 0), 1)

            let byteR = UInt8(vR * 255)
            let byteG = UInt8(vG * 255)
            let byteB = UInt8(vB * 255)

            let offset = i * bytesPerPixel
            buffer[offset + 0] = byteR // R
            buffer[offset + 1] = byteG // G
            buffer[offset + 2] = byteB // B
            buffer[offset + 3] = 255   // A
        }

        return ctx.makeImage()
    }

    // Box–Muller transform to sample N(0,1)
    private static func sampleStandardNormal() -> Float {
        let u1 = max(Float.random(in: 0..<1), .leastNonzeroMagnitude)
        let u2 = Float.random(in: 0..<1)
        let r = sqrt(-2 * log(u1))
        let theta = 2 * Float.pi * u2
        return r * cos(theta)
    }
}

struct ForwardDiffusionLabView_Previews: PreviewProvider {
    static var previews: some View {
        ForwardDiffusionLabView()
    }
}
