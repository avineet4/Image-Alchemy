import SwiftUI
import Charts

private let knowledgeColor = Color(red: 0.56, green: 0.49, blue: 0.43)

private enum OnboardingPage: Int, CaseIterable {
    case pipeline
    case maths
    case knowledge
    case getStarted

    var title: String {
        switch self {
        case .pipeline: return "Full Pipeline"
        case .maths: return "Related Maths"
        case .knowledge: return "Test Your Knowledge"
        case .getStarted: return "You're All Set"
        }
    }

    var subtitle: String {
        switch self {
        case .pipeline:
            return "Explore the full pipeline, from encoding to denoising."
        case .maths:
            return "Dive into the mathematics behind diffusion-probability, vectors, and more."
        case .knowledge:
            return "Reinforce concepts with flashcards, quizzes, and matching exercises."
        case .getStarted:
            return "Tap Get Started to open the home screen and choose where to begin."
        }
    }

    var icon: String {
        switch self {
        case .pipeline: return "play.circle.fill"
        case .maths: return "function"
        case .knowledge: return "book.fill"
        case .getStarted: return "checkmark.circle.fill"
        }
    }
}

// Onboarding flow shown on first launch. Uses MeshGradientBackgroundLight as background.
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage: Int = 0
    @State private var showLaunch = true
    @State private var showGetStartedButton = false
    @State private var isDarkBackground = true

    private static let textTransition = AnyTransition.asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.92)).combined(with: .offset(y: 20)),
        removal: .opacity.combined(with: .scale(scale: 0.96)).combined(with: .offset(y: -12))
    )

    private var page: OnboardingPage {
        OnboardingPage(rawValue: currentPage) ?? .pipeline
    }

    var body: some View {
        ZStack {
            RippleOnboardingBackground(isDarkBackground: $isDarkBackground)

            if showLaunch {
                VStack(spacing: 40) {
                    XcodeOnBoardingView(foregroundColor: colorScheme == .dark ? .white : .black, tint: colorScheme == .dark ? .black : .white) { isAnimating in
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 470, height: 470)
                            .blendMode(.softLight)
                            .scaleEffect(isAnimating ? 0.5 : 1)
                    } content: { isAnimating in
                        VStack(spacing: 15) {
                            Text("Welcome to Image Alchemy")
                                .font(.largeTitle.bold())
                                .fontWidth(.expanded)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .offset(y: 20)
                        }
                        .padding(.top, 20)
                    }
                    onAnimationComplete: {
                        withAnimation(.easeInOut(duration: 0.3)) { showGetStartedButton = true }
                    }
                    .scaleEffect(1.2)

                    if showGetStartedButton {
                        Button {
                            withAnimation { showLaunch = false }
                        } label: {
                            Text("Get Started")
                                .fontWeight(.semibold)
                                .fontWidth(.expanded)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .frame(maxWidth: 420)
                                .padding(.vertical, 14)
                        }
                        .modifier(GetStartedButtonStyle(colorScheme: colorScheme))
                        .padding(.top, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.3), value: showGetStartedButton)
                .onChange(of: showLaunch) { _, newValue in
                    if newValue { showGetStartedButton = false }
                }
            } else {
                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        ForEach(OnboardingPage.allCases, id: \.rawValue) { p in
                            onboardingPageContent(p, isDarkBackground: isDarkBackground, currentPage: currentPage)
                                .tag(p.rawValue)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.35), value: currentPage)
                    .frame(maxWidth: .infinity)

                    pageIndicator
                        .padding(.vertical, 24)

                    controlsRow
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showLaunch)
        .ignoresSafeArea()
    }

    private var controlsRow: some View {
        HStack(spacing: 16) {
            previousButton
            Spacer(minLength: 16)
            nextButton
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }

    @ViewBuilder
    private func onboardingPageContent(_ p: OnboardingPage, isDarkBackground: Bool, currentPage: Int) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            VStack(spacing: 32) {
                if p == .pipeline {
                PipelineDecoderStaticPreview(isDarkBackground: isDarkBackground)
                        .frame(width: 420, height: 420)
                        .shadow(color: isDarkBackground ? .white.opacity(0.2) : .black.opacity(0.2), radius: 20, y: 8)
                        .scaleEffect(1.3)
                        .offset(x: -15)
                        .accessibilityHidden(true)
                } else if p == .maths {
                    RelatedMathsRevolvingChartPreview()
                        .frame(width: 420, height: 420)
                        .shadow(color: isDarkBackground ? .white.opacity(0.2) : .black.opacity(0.2), radius: 20, y: 8)
                        .accessibilityHidden(true)
                } else if p == .knowledge {
                    KnowledgeTestPreview(isDarkBackground: isDarkBackground)
                        .frame(width: 420, height: 420)
                        .shadow(color: isDarkBackground ? .white.opacity(0.2) : .black.opacity(0.2), radius: 20, y: 8)
                        .accessibilityHidden(true)
                        .offset(y: -25)
                } else {
                    Image(systemName: p.icon)
                        .font(.system(size: 104, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isDarkBackground ? .white : .black)
                        .shadow(color: isDarkBackground ? .white.opacity(0.2) : .black.opacity(0.2), radius: 20, y: 8)
                        .symbolEffect(.bounce, value: currentPage)
                        .scaleEffect(currentPage == OnboardingPage.getStarted.rawValue ? 1 : 0.94)
                        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: currentPage)
                }

                VStack(spacing: 16) {
                    Text(p.title)
                        .font(.system(size: 28, weight: .bold))
                        .fontWidth(.expanded)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(isDarkBackground ? .white : .black)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)

                    Text(p.subtitle)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(isDarkBackground ? .white.opacity(0.9) : .black.opacity(0.9))
                        .lineSpacing(8)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            // .background(
            //     RoundedRectangle(cornerRadius: 28)
            //         .fill(.ultraThinMaterial.opacity(0.4))
            //         .overlay(
            //             RoundedRectangle(cornerRadius: 28)
            //                 .stroke(.white.opacity(0.15), lineWidth: 1)
            //         )
            // )
            .padding(.horizontal, 8)
            .scaleEffect(1.2)
            .transition(Self.textTransition)

            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<OnboardingPage.allCases.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentPage
                        ? (isDarkBackground ? Color.white : Color.black)
                        : (isDarkBackground ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
                    )
                    .frame(width: index == currentPage ? 28 : 10, height: 10)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
            }
        }
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private var previousButton: some View {
        if currentPage > 0 {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage -= 1
                }
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .frame(minWidth: 120, minHeight: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            // .tint(.white)
        } else {
            Color.clear
                .frame(width: 120, height: 48)
        }
    }

    private var nextButton: some View {
        Button {
            if currentPage < OnboardingPage.allCases.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
            } else {
                completeOnboarding()
            }
        } label: {
            Label(
                currentPage == OnboardingPage.allCases.count - 1 ? "Get Started" : "Next",
                systemImage: currentPage == OnboardingPage.allCases.count - 1 ? "checkmark" : "chevron.right"
            )
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(minWidth: 120, minHeight: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.glass)
        // .tint(.white)
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.35)) {
            hasCompletedOnboarding = true
        }
    }
}

private struct RelatedMathsRevolvingChartPreview: View {
    @State private var pose = Chart3DPose(
        azimuth: .degrees(40),
        inclination: .degrees(28)
    )

    private let mean = 0.0
    private let stdDev = 0.40
    private let coeff: Double
    private let factor: Double

    init() {
        coeff = 1.0 / (2 * .pi * stdDev * stdDev)
        factor = 1.0 / (2 * stdDev * stdDev)
    }

    var body: some View {
        Chart3D {
            SurfacePlot(x: "x", y: "y", z: "p(x,y)") { x, y in
                let dx = x - mean
                let dy = y - mean
                return coeff * exp(-(dx * dx + dy * dy) * factor)
            }
            .foregroundStyle(.heightBased)
        }
        .chart3DPose($pose)
        .chart3DCameraProjection(.perspective)
        .allowsHitTesting(false)
        .task { await revolve() }
    }

    private func revolve() async {
        let fps = 30.0
        let degreesPerSecond = 12.0
        let step = degreesPerSecond / fps

        var azimuth = 40.0
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1.0 / fps))
            azimuth += step
            if azimuth >= 360 { azimuth -= 360 }
            pose = Chart3DPose(azimuth: .degrees(azimuth), inclination: .degrees(28))
        }
    }
}

private struct KnowledgeTestPreview: View {
    let isDarkBackground: Bool

    var body: some View {
        ZStack {

            HStack {
                OnboardingFlashcardPreview(term: "Diffusion", color: knowledgeColor, isDarkBackground: isDarkBackground)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -40)

                Spacer()

                QuizPreviewVisual(color: knowledgeColor)
                    .frame(maxWidth: 200)
                    .rotationEffect(.degrees(20))
                    .offset(x: 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -30)


            VStack(alignment: .center, spacing: 25) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 90, weight: .semibold))
                    .foregroundStyle(
                        MeshGradient(width: 2, height: 2, points: [
                            [0, 0], [1, 0],
                            [0, 1], [1, 1],
                        ], colors: [
                            .pink, .indigo,
                            .indigo, .blue,
                        ])
                    )
                    .shadow(color: (isDarkBackground ? Color.white : Color.black).opacity(0.3), radius: 12, x: 0, y: 4)

                Text("AI Generated flashcards, quiz, and more.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(isDarkBackground ? .white.opacity(0.9) : .black.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .offset(y: -30)

            HStack {
                MatchTheFollowingPreviewVisual(color: knowledgeColor)
                    .frame(maxWidth: 250)
                    .rotationEffect(.degrees(20))
                    .offset(x: -65)

                Spacer()

                Text("Diffusion")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    // .padding(5)
                    // .padding(.horizontal, 10)
                    // .padding(.vertical, 10)
                    .glassEffect(.clear.tint(knowledgeColor), in: .capsule)
                    .shadow(color: knowledgeColor, radius: 12, x: 0, y: 6)
//                    .modifier(
//                        _RotationEffect(angle:
//                                .degrees(-15))
//                                .ignoredByLayout()
//                    )
                    .rotationEffect(.degrees(-15))
                    .frame(height: 5)
                    // .offset(x: -40 ,y: 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

private struct OnboardingFlashcardPreview: View {
    let term: String
    let color: Color
    let isDarkBackground: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text("TERM")
                .font(.system(size: 12, weight: .semibold))
                .fontWidth(.condensed)
                .foregroundStyle(color.opacity(0.9))
            Text(term)
                .font(.system(size: 20, weight: .medium))
                .fontWidth(.expanded)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(minWidth: 180, minHeight: 130)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
                .shadow(color: (isDarkBackground ? Color.white : .black).opacity(isDarkBackground ? 0.15 : 0.12), radius: 12, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

private struct QuizPreviewVisual: View {
    let color: Color

    // private static let sampleQuestion = "What does the forward process do?"
    private static let sampleOptions = ["Adds noise", "Removes noise", "Compresse images"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 16) {
                ForEach(Array(Self.sampleOptions.enumerated()), id: \.offset) { index, option in
                    HStack(spacing: 10) {
                        Text(optionLabel(for: index))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color(red: 0.28, green: 0.18, blue: 0.12)))
                        Text(option)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(color)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .offset(y: 10)
    }

    private func optionLabel(for index: Int) -> String {
        let labels = ["A", "B", "C", "D"]
        return index >= 0 && index < labels.count ? labels[index] : "?"
    }
}

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
                                .background(Circle().fill(Color(red: 0.28, green: 0.18, blue: 0.12)))
                            Text(item.text)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color)
                        )
                        .background(framePreference(isLeft: true, index: index))

                        Spacer(minLength: 12)

                        Text(definition)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(alignment: .trailing)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(color)
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

private struct PipelineDecoderStaticPreview: View {
    let isDarkBackground: Bool

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 5) {
                HStack(alignment: .center, spacing: 24) {
                    VStack(spacing: 12) {
                        PipelineDecoderNodeDiagramPreview(isDarkBackground: isDarkBackground)
                            .frame(width: 420, height: 340)
                    }
                    .padding(10)
                }
                .scaleEffect(0.8)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .padding()
        }
    }
}

private struct PipelineDecoderNodeDiagramPreview: View {
    let isDarkBackground: Bool

    private let latentCount = 4
    private let hiddenCount = 8
    private let pixelCount = 6
    private let nodeRadius: CGFloat = 12

    @State private var activeLatentIndex: Int = -1
    @State private var pathProgress: CGFloat = 1.0
    @State private var hiddenConnectProgress: [CGFloat] = Array(repeating: 1.0, count: 8)
    @State private var pixelConnectProgress: [CGFloat] = Array(repeating: 1.0, count: 6)
    @State private var hasStartedAnimations: Bool = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            let latentX = width * 0.2
            let hiddenX = width * 0.5
            let pixelX = width * 0.8

            let latentSpacing = height / CGFloat(latentCount + 1)
            let hiddenSpacing = height / CGFloat(hiddenCount + 1)
            let pixelSpacing = height / CGFloat(pixelCount + 1)

            ZStack {
                ForEach(0..<latentCount, id: \.self) { i in
                    let yLat = latentSpacing * CGFloat(i + 1)
                    ForEach(0..<hiddenCount, id: \.self) { j in
                        let yHid = hiddenSpacing * CGFloat(j + 1)
                        Path { path in
                            path.move(to: CGPoint(x: latentX, y: yLat))
                            path.addLine(to: CGPoint(x: hiddenX, y: yHid))
                        }
                        .trim(from: 0, to: hiddenConnectProgress[j])
                        .stroke(isDarkBackground ? .white.opacity(0.25) : .black.opacity(0.25), lineWidth: 1)
                    }
                }

                ForEach(0..<hiddenCount, id: \.self) { j in
                    let yHid = hiddenSpacing * CGFloat(j + 1)
                    ForEach(0..<pixelCount, id: \.self) { k in
                        let yPix = pixelSpacing * CGFloat(k + 1)
                        Path { path in
                            path.move(to: CGPoint(x: hiddenX, y: yHid))
                            path.addLine(to: CGPoint(x: pixelX, y: yPix))
                        }
                        .trim(from: 0, to: pixelConnectProgress[k])
                        .stroke(isDarkBackground ? .white.opacity(0.25) : .black.opacity(0.25), lineWidth: 1)
                    }
                }

                // Highlighted connections (active latent path)
                if activeLatentIndex >= 0 && activeLatentIndex < latentCount {
                    let activeHiddenIndex = activeLatentIndex % hiddenCount
                    let activePixelIndex = activeLatentIndex % pixelCount

                    let yLatSingle = latentSpacing * CGFloat(activeLatentIndex + 1)
                    let yHidSingle = hiddenSpacing * CGFloat(activeHiddenIndex + 1)

                    ForEach(0..<hiddenCount, id: \.self) { j in
                        let yHid = hiddenSpacing * CGFloat(j + 1)
                        Path { path in
                            path.move(to: CGPoint(x: latentX + nodeRadius, y: yLatSingle))
                            path.addLine(to: CGPoint(x: hiddenX - nodeRadius, y: yHid))
                        }
                        .trim(from: 0, to: pathProgress)
                        .stroke(
                            Color.pink.opacity(j == activeHiddenIndex ? 0.95 : 0.6),
                            lineWidth: j == activeHiddenIndex ? 3 : 2
                        )
                    }

                    ForEach(0..<pixelCount, id: \.self) { k in
                        let yPix = pixelSpacing * CGFloat(k + 1)
                        Path { path in
                            path.move(to: CGPoint(x: hiddenX + nodeRadius, y: yHidSingle))
                            path.addLine(to: CGPoint(x: pixelX - nodeRadius, y: yPix))
                        }
                        .trim(from: 0, to: pathProgress)
                        .stroke(
                            Color.green.opacity(k == activePixelIndex ? 0.95 : 0.6),
                            lineWidth: k == activePixelIndex ? 3 : 2
                        )
                    }
                }

                // Nodes
                ForEach(0..<latentCount, id: \.self) { i in
                    let y = latentSpacing * CGFloat(i + 1)
                    decoderNode(isActive: i == activeLatentIndex, color: .cyan, activeScale: 1.12)
                        .position(x: latentX, y: y)
                }

                ForEach(0..<hiddenCount, id: \.self) { j in
                    let y = hiddenSpacing * CGFloat(j + 1)
                    decoderNode(isActive: j == (activeLatentIndex % hiddenCount), color: .cyan, activeScale: 1.08)
                        .position(x: hiddenX, y: y)
                }

                ForEach(0..<pixelCount, id: \.self) { k in
                    let y = pixelSpacing * CGFloat(k + 1)
                    decoderNode(isActive: k == (activeLatentIndex % pixelCount), color: .cyan, activeScale: 1.08)
                        .position(x: pixelX, y: y)
                }

                // Column labels
                Text("Latent Channels")
                    .font(.caption)
                    .foregroundStyle(isDarkBackground ? .white : .black)
                    .position(x: latentX, y: 10)
                Text("Decoded Features")
                    .font(.caption)
                    .foregroundStyle(isDarkBackground ? .white : .black)
                    .position(x: hiddenX, y: 10)
                Text("Pixel Features")
                    .font(.caption)
                    .foregroundStyle(isDarkBackground ? .white : .black)
                    .position(x: pixelX, y: 10)
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.9), value: activeLatentIndex)
        }
        .task {
            guard !hasStartedAnimations else { return }
            hasStartedAnimations = true
            await runLoopingAnimations()
        }
    }

    @ViewBuilder
    private func decoderNode(isActive: Bool, color: Color, activeScale: CGFloat) -> some View {
        Circle()
            .stroke(isActive ? color : color.opacity(0.5), lineWidth: 2)
            .background(
                Circle().fill(
                    isActive ? color.opacity(0.18) : Color.white
                )
            )
            .frame(width: nodeRadius * 2, height: nodeRadius * 2)
            .scaleEffect(isActive ? activeScale : 1.0)
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: 4, y: 2)
    }

    private func runLoopingAnimations() async {
        await runLayerFanoutAndInitialPath()

        // After the initial fan-out, softly cycle the active path
        let pathDuration: TimeInterval = 0.7
        let pauseBetweenCycles: TimeInterval = 0.25

        while !Task.isCancelled {
            // Select the next latent to highlight
            await MainActor.run {
                activeLatentIndex = (activeLatentIndex + 1) % max(latentCount, 1)
            }

            // Run the highlight animation for this latent
            await animateActivePath()
            try? await Task.sleep(for: .seconds(pathDuration))

            // Clear the highlight during the pause between pulses
            await MainActor.run {
                pathProgress = 0
            }
            try? await Task.sleep(for: .seconds(pauseBetweenCycles))
        }
    }

    private func runLayerFanoutAndInitialPath() async {
        await MainActor.run {
            hiddenConnectProgress = Array(repeating: 0, count: hiddenCount)
            pixelConnectProgress = Array(repeating: 0, count: pixelCount)
            pathProgress = 0
        }

        // Slightly overlapped, smooth fan-out across layers
        let fanInterval: TimeInterval = 0.1
        let fanDuration: TimeInterval = 0.6

        for j in 0..<hiddenCount {
            await MainActor.run {
                withAnimation(.smooth(duration: fanDuration)) {
                    hiddenConnectProgress[j] = 1.0
                }
            }
            try? await Task.sleep(for: .seconds(fanInterval))
        }

        try? await Task.sleep(for: .seconds(fanInterval * 2))
        for k in 0..<pixelCount {
            await MainActor.run {
                withAnimation(.smooth(duration: fanDuration)) {
                    pixelConnectProgress[k] = 1.0
                }
            }
            try? await Task.sleep(for: .seconds(fanInterval))
        }

        // await animateActivePath()
    }

    private func animateActivePath() async {
        await MainActor.run {
            let duration: TimeInterval = 0.7
            pathProgress = 0
            withAnimation(.smooth(duration: duration)) {
                pathProgress = 1
            }
        }
    }
}

private struct GetStartedButtonStyle: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if colorScheme == .light {
            content
                .tint(.white.opacity(0.7))
                .buttonStyle(.glassProminent)
        } else {
            content
                .buttonStyle(.glass)
        }
    }
}

private struct RippleOnboardingBackground: View {
    @Binding var isDarkBackground: Bool
    @State private var progress: Float = 0
    @State private var isAnimating = false
    @State private var tapLocation = CGSize(width: 0, height: 0)

    var body: some View {
        GeometryReader { _ in
            ZStack {
                if isDarkBackground {
                    MeshGradientBackgroundLight()
                    MeshGradientBackgroundDark()
                        .visualEffect { content, _ in
                            content.layerEffect(
                                ShaderLibrary.RippleEffect(
                                    .float2(tapLocation),
                                    .float(Double(progress) * 3),
                                    .float(12),
                                    .float(15),
                                    .float(8),
                                    .float(1200)
                                ),
                                maxSampleOffset: .init(width: 12, height: 12)
                            )
                        }
                } else {
                    MeshGradientBackgroundDark()
                    MeshGradientBackgroundLight()
                        .visualEffect { content, _ in
                            content.layerEffect(
                                ShaderLibrary.RippleEffect(
                                    .float2(tapLocation),
                                    .float(Double(progress) * 3),
                                    .float(12),
                                    .float(15),
                                    .float(8),
                                    .float(1200)
                                ),
                                maxSampleOffset: .init(width: 12, height: 12)
                            )
                        }
                }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !isAnimating else { return }

                        let loc = value.location
                        tapLocation = CGSize(width: loc.x, height: loc.y)

                        isAnimating = true
                        progress = 0
                        withAnimation(.easeInOut(duration: 1.5)) {
                            progress = 1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            isDarkBackground.toggle()
                            progress = 0
                            isAnimating = false
                        }
                    }
            )
        }
    }
}

// MARK: - Preview

private struct OnboardingPreviewRoot: View {
    @State private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

#Preview {
    OnboardingPreviewRoot()
}
