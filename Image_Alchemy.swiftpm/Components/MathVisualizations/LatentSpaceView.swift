import SwiftUI
import Charts

struct LatentSpaceView: View {
    private static func rand(_ c: Int, _ i: Int) -> Double {
        var h = UInt32(bitPattern: Int32(c &* 31 &+ i))
        h = h &* 0x9E3779B1
        h ^= h >> 16
        h = h &* 0x85EBCA6B
        h ^= h >> 13
        return Double(Int32(bitPattern: h)) / 2147483648.0
    }

    static let sampleLatentData: [LatentPoint] = {
        var points: [LatentPoint] = []
        let configs: [(cx: Double, cy: Double, cz: Double, sx: Double, sy: Double, sz: Double, density: Double, outlierPct: Double, category: String)] = [
            (-2.2, -1.8, -1.5, 0.55, 0.5, 0.52, 0.2, 0.08, "Portrait"),
            (-0.5, 0.8, 0.2, 0.48, 0.72, 0.45, 0.3, 0.05, "Nature"),
            (1.5, 1.2, 1.8, 0.52, 0.48, 0.58, 0.25, 0.06, "Urban"),
            (2.5, -0.5, -1.2, 0.45, 0.55, 0.42, 0.35, 0.04, "Abstract")
        ]
        for (c, config) in configs.enumerated() {
            for i in 0..<120 {
                let r1 = rand(c, i * 3)
                let r2 = rand(c, i * 3 + 1)
                let r3 = rand(c, i * 3 + 2)
                let r = sqrt(r1 * r1 + r2 * r2 + r3 * r3) / 1.73
                let falloff = 1.0 - config.density * r
                let isOutlier = (rand(c, i + 200) + 1) / 2 < config.outlierPct
                let b = isOutlier ? 1.6 : 1.0
                let dx = r1 * config.sx * max(0.4, falloff) * b
                let dy = r2 * config.sy * max(0.4, falloff) * b
                let dz = r3 * config.sz * max(0.4, falloff) * b
                points.append(LatentPoint(
                    x: config.cx + dx,
                    y: config.cy + dy,
                    z: config.cz + dz,
                    category: config.category
                ))
            }
        }
        return points
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            EquationDisplay(
                equation: "x → z = Encoder(x)  →  diffusion in z  →  x̂ = Decoder(z)",
                label: "Latent diffusion pipeline"
            )

            LatentPipelineView()

            Divider()

            LatentSpaceScatterView(data: LatentSpaceView.sampleLatentData)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("What this implies")
                    .font(.headline)

                bullet("**Clustering** = The VAE learns to map similar images to nearby points. Each concept forms its own region.")
                bullet("**Semantic structure** = Distance in latent space reflects perceptual similarity. Close points → similar images.")
                bullet("**Efficient denoising** = Diffusion adds noise in this structured space. The model learns to denoise along meaningful directions.")
                bullet("**Interpolation** = Walking between clusters (e.g. Portrait → Nature) can blend concepts-useful for guided generation.")
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Why latent space?")
                    .font(.subheadline.weight(.semibold))

                HStack(alignment: .top, spacing: 16) {
                    LatentBenefitCard(
                        title: "Efficiency",
                        content: "512×512×3 ≈ 786K pixels → 64×64×4 ≈ 16K latent dims. ~50× smaller.",
                        icon: "bolt.fill"
                    )
                    LatentBenefitCard(
                        title: "Quality",
                        content: "VAE learns perceptual features. Diffusion operates on meaningful structure.",
                        icon: "sparkles"
                    )
                }
            }

            Divider()

            RichText(text: "Models like **Stable Diffusion** use a VAE (Variational Autoencoder) to compress images into latent space first. The forward/reverse diffusion equations you learned apply **in z**, not in pixel space. The decoder maps denoised latents back to images.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Key ideas")
                    .font(.headline)

                bullet("**Encoder**: x₀ → z₀. Compresses image to a lower-dimensional latent vector.")
                bullet("**Latent space**: Smaller, learned representation. Diffusion adds/removes noise here.")
                bullet("**Decoder**: z₀ → x̂. Reconstructs image from latent. Same VAE used for encode/decode.")
            }
        }
        .padding()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            RichText(text: text)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Supporting Views

private struct LatentPipelineView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pixel space → Latent space → Diffusion → Decode")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                PipelineBlock(label: "Image", dims: "512×512×3", color: .cyan)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                PipelineBlock(label: "Encoder", dims: "VAE", color: .cyan.opacity(0.8))
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                PipelineBlock(label: "z (latent)", dims: "64×64×4", color: .cyan, isCompact: true)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                PipelineBlock(label: "Diffusion", dims: "U-Net", color: .purple.opacity(0.8))
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                PipelineBlock(label: "Decoder", dims: "VAE", color: .cyan.opacity(0.8))
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                PipelineBlock(label: "Image", dims: "512×512×3", color: .cyan)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
    }
}

private struct PipelineBlock: View {
    let label: String
    let dims: String
    let color: Color
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
            Text(dims)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, isCompact ? 8 : 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.15))
        )
    }
}

private struct LatentBenefitCard: View {
    let title: String
    let content: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.cyan)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            Text(content)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cyan.opacity(0.08))
        )
    }
}

// Interactive 3D scatter plot of learned latent representations using Chart3D.
private struct LatentSpaceScatterView: View {
    let data: [LatentPoint]
    @State private var pose = Chart3DPose(azimuth: .degrees(35), inclination: .degrees(25))
    @State private var isFullScreen = false
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Learned representations in 3D latent space")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            pose = Chart3DPose(azimuth: .degrees(35), inclination: .degrees(25))
                        }
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

            Text("Simulated clusters: similar images map to nearby points. Drag to rotate.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart3D(data) { point in
                PointMark(
                    x: .value("z₁", point.x),
                    y: .value("z₂", point.y),
                    z: .value("z₃", point.z)
                )
                .foregroundStyle(LatentCategory.all.first { $0.id == point.category }?.color ?? .gray)
            }
            .chart3DPose($pose)
            .chart3DCameraProjection(.perspective)
            .chartXAxisLabel("z₁")
            .chartYAxisLabel("z₂")
            .chartZAxisLabel("z₃")
            .chartXScale(domain: -4...4, range: -0.5...0.5)
            .chartYScale(domain: -4...4, range: -0.5...0.5)
            .chartZScale(domain: -4...4, range: -0.5...0.5)
            .frame(height: 280)
            // Subtle entrance animation: fade & ease-in scale for the 3D scatter.
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.96)
            .animation(.smooth(duration: 0.45), value: hasAppeared)

            LatentLegendView()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
            }
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            LatentSpaceFullScreenView(data: data, onDismiss: { isFullScreen = false })
        }
    }
}

// Full-screen chart presentation with close button.
private struct LatentSpaceFullScreenView: View {
    let data: [LatentPoint]
    let onDismiss: () -> Void
    @State private var pose = Chart3DPose(azimuth: .degrees(35), inclination: .degrees(25))

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Chart3D(data) { point in
                    PointMark(
                        x: .value("z₁", point.x),
                        y: .value("z₂", point.y),
                        z: .value("z₃", point.z)
                    )
                    .foregroundStyle(LatentCategory.all.first { $0.id == point.category }?.color ?? .gray)
                }
                .chart3DPose($pose)
                .chart3DCameraProjection(.perspective)
                .chartXAxisLabel("z₁")
                .chartYAxisLabel("z₂")
                .chartZAxisLabel("z₃")
                .chartXScale(domain: -4...4, range: -0.5...0.5)
                .chartYScale(domain: -4...4, range: -0.5...0.5)
                .chartZScale(domain: -4...4, range: -0.5...0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))

                LatentLegendView()
                    .padding()
                    .background(Color(.systemBackground))
            }

            HStack(spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pose = Chart3DPose(azimuth: .degrees(35), inclination: .degrees(25))
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.black)
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

private struct LatentLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categories (image types)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(LatentCategory.all) { category in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 10, height: 10)
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(category.color)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(category.name)
                                .font(.caption.weight(.medium))
                            RichText(text: category.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(category.color.opacity(0.08))
                    )
                }
            }
        }
    }
}
