import SwiftUI
import Foundation

struct KnowledgeModeCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    private let cardCornerRadius: CGFloat = 20
    private let topCornerRadius: CGFloat = 20

    var body: some View {
        NavigationLink(destination: destination()) {
            ZStack(alignment: .bottom) {
                topSection
                bottomSection
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(Color.primary.opacity(0.9), lineWidth: 3.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var topSection: some View {
        ZStack {
            // LinearGradient(
            //     colors: [
            //         color.opacity(0.35),
            //         color.opacity(0.15)
            //     ],
            //     startPoint: .topLeading,
            //     endPoint: .bottomTrailing
            // )
            if title == "Flashcards" {
                FullPipelineCardTopSection(color: color)

                ZStack {
                    FlashcardPreviewVisual(term: "U-Net", color: color)
                        .rotationEffect(.degrees(10))
                        .offset(x: 24)
                    FlashcardPreviewVisual(term: "Diffusion", color: color)
                        .rotationEffect(.degrees(-10))
                        .offset(x: -24)
                }
                .padding(20)
                .offset(y: -50)
            } else if title == "Quiz" {
                FullPipelineCardTopSection(color: color)

                QuizPreviewVisual(color: color)
                    .padding(20)
                    .offset(y: -50)
            } else if title == "Match the Following" {
                MatchTheFollowingPreviewVisual(color: color)
                    .padding(20)
            } else if title == "Fill in the Blanks" {
                ZStack {
                    FillInTheBlanksPreviewVisual(color: color)

                    // Centered glass capsule label over the top section
                    Text("Diffusion Model")
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .padding(.horizontal, 31)
                        .padding(.vertical, 24)
                        .glassEffect(.regular, in: .capsule)
                        .offset(y: -50)
                }
                .padding(20)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(color.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: topCornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: topCornerRadius
            )
        )
    }

    private var bottomSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .black, design: .default))
                    .fontWidth(.expanded)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .default))
                    .fontWidth(.expanded)
                    .foregroundStyle(.primary.opacity(0.9))
            }
        }
        .padding(16)
        .frame(height: 110)
        .frame(maxWidth: .infinity, alignment: .leading)
        // .background(color)
        // .clipShape(
        //     UnevenRoundedRectangle(
        //         topLeadingRadius: 0,
        //         bottomLeadingRadius: cardCornerRadius,
        //         bottomTrailingRadius: cardCornerRadius,
        //         topTrailingRadius: 0
        //     )
        // )
        .glassEffect(
            .regular,
            in: UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cardCornerRadius,
                bottomTrailingRadius: cardCornerRadius,
                topTrailingRadius: 0
            )
        )
    }
}

private struct FullPipelineCardTopSection: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            Canvas { context, _ in
                let spacing: CGFloat = 30
                let radius: CGFloat = 1.9

                for row in stride(from: 0 as CGFloat, through: size.height + spacing, by: spacing) {
                    for column in stride(from: 0 as CGFloat, through: size.width + spacing, by: spacing) {
                        let x = column
                        let y = row

                        let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                        let path = Path(ellipseIn: rect)
                        context.fill(path, with: .color(color.opacity(0.5)))
                    }
                }
            }
        }
    }
}

// MARK: - Flashcard preview (non-interactive)

// Small flashcard-style visual for the Flashcards mode card preview.
private struct FlashcardPreviewVisual: View {
    let term: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("TERM")
                .font(.system(size: 14, weight: .semibold))
                .fontWidth(.condensed)
                .foregroundStyle(color.opacity(0.9))
            Text(term)
                .font(.system(size: 24, weight: .medium))
                .fontWidth(.expanded)
                .foregroundStyle(.black.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(minWidth: 160, minHeight: 130)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quiz preview (non-interactive)

// Quiz-style visual for the Quiz mode card preview: question + multiple-choice options.
private struct QuizPreviewVisual: View {
    let color: Color

    private static let sampleQuestion = "What does the forward process do?"
    private static let sampleOptions = ["Adds noise over time", "Removes noise", "Compresses images"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Self.sampleQuestion)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.9))
                .lineLimit(2)

            VStack(spacing: 8) {
                ForEach(Array(Self.sampleOptions.enumerated()), id: \.offset) { index, option in
                    HStack(spacing: 12) {
                        Text(optionLabel(for: index))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(color))
                        Text(option)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.primary.opacity(0.85))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .glassEffect(.regular.tint(color.opacity(0.5)), in: Capsule())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func optionLabel(for index: Int) -> String {
        let labels = ["A", "B", "C", "D"]
        return index >= 0 && index < labels.count ? labels[index] : "?"
    }
}

// MARK: - Match the Following preview (non-interactive)

private struct MatchTheFollowingPreviewVisual: View {
    let color: Color

    private static let leftItems: [(label: String, text: String)] = [
        ("A", "Forward"),
        ("B", "U-Net"),
        ("C", "Latent space")
    ]
    private static let rightItems: [String] = [
        "Predicts noise ε",
        "Compressed space",
        "Adds noise"
    ]
    private static let leftToRightMatch: [Int] = [2, 0, 1]

    private static var pairs: [MatchPair] {
        (0..<3).map { i in
            MatchPair(leftItem: leftItems[i].text, rightItem: rightItems[leftToRightMatch[i]])
        }
    }

    private static var userMatches: [Int: Int] {
        Dictionary(uniqueKeysWithValues: (0..<3).map { ($0, leftToRightMatch[$0]) })
    }

    private let rowCount = 3
    @State private var itemFrames: [MatchItemFrame] = []

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.12))
                    .overlay(
                        GridPattern()
                            .stroke(color.opacity(0.18), lineWidth: 0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
//                    .padding(.bottom, 110)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.12))
                    .overlay(
                        GridPattern()
                            .stroke(color.opacity(0.18), lineWidth: 0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                    .frame(height: 90)
                
                
            }

            VStack(spacing: 6) {
                ForEach(0..<rowCount, id: \.self) { index in
                    let item = Self.leftItems[index]
                    let definition = Self.rightItems[index]

                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text(item.label)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(color))
                            Text(item.text)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.85))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.2))
                        )
                        .background(framePreference(isLeft: true, index: index))

                        Spacer(minLength: 12)

                        Text(definition)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(.primary.opacity(0.85))
                            .frame(alignment: .trailing)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(color.opacity(0.2))
                            )
                            .background(framePreference(isLeft: false, index: index))
                    }
                }
            }
            .padding(10)
            .coordinateSpace(name: "matchArea")
            .overlay(
                MatchLinesOverlay(
                    userMatches: Self.userMatches,
                    itemFrames: itemFrames,
                    hasChecked: false,
                    pairs: Self.pairs,
                    rightItems: Self.rightItems
                )
            )
            .onPreferenceChange(MatchFramePreferenceKey.self) { frames in
                itemFrames = frames
            }
            .offset(y: -50)
        }
    }

    private func framePreference(isLeft: Bool, index: Int) -> some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .named("matchArea"))
            Color.clear.preference(
                key: MatchFramePreferenceKey.self,
                value: [MatchItemFrame(
                    isLeft: isLeft,
                    index: index,
                    midX: Double(frame.midX),
                    midY: Double(frame.midY),
                    minX: Double(frame.minX),
                    maxX: Double(frame.maxX)
                )]
            )
        }
    }
}

// Simple grid stroke for the Match the Following background.
private struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let step: CGFloat = 10

        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += step
        }

        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += step
        }

        return path
    }
}

// MARK: - Fill in the Blanks preview (non-interactive)

private struct FillInTheBlanksPreviewVisual: View {
    let color: Color

    private var paragraph: Text {
        let blank = Text("_____")
            .foregroundStyle(color)
            .underline(true, color: color.opacity(0.6))
        return Text("In diffusion models, the \(blank) process gradually adds \(blank) noise to an image over T timesteps until it becomes pure noise. The model learns to predict the noise ε at each step. A \(blank) is often used to predict this noise, and the noise schedule βₜ controls how much is added at each timestep. Latent diffusion runs in a compressed space from a \(blank) for efficiency. At t = 0 the image is clean; at t = T it is fully noised.")
    }

    var body: some View {
        paragraph
            .font(.system(size: 18, weight: .semibold, design: .default))
            .fontWidth(.expanded)
            .foregroundStyle(.primary.opacity(0.5))
            .multilineTextAlignment(.leading)
            .lineSpacing(8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
