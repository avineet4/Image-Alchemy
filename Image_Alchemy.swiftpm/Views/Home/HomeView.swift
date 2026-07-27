import SwiftUI
import Charts

// Warm golden accent derived from the logo's peach–yellow gradient,
// chosen to sit between the purple top text and yellow bottom text.
private let homeCardAccentColor = Color(red: 0.95, green: 0.64, blue: 0.36)
private let knowledgeColor = Color(red: 0.56, green: 0.49, blue: 0.43)

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var isInfoSheetPresented = false
    @State private var isHelpSheetPresented = false

    init(viewModel: HomeViewModel = HomeViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    HeaderSection()
                    .frame(maxHeight: .infinity)
                    
                    NavigationCardsSection(items: viewModel.navigationItems)
                    .offset(y: -50)
                    
                    Spacer()
                    // Appearance toggle at the bottom
                    AppearanceToggle(
                        currentAppearance: viewModel.appearance,
                        onCycle: viewModel.cycleAppearance,
                        onShowPicker: viewModel.presentAppearancePicker
                    )
                    .padding(.bottom, 30)
                }
                
                HStack(spacing: 0) {
                    Button {
                        isHelpSheetPresented = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.title)
                            .padding(16)
                            .foregroundStyle(.gray)
                    }
                    .offset(x: 20)

                    Button {
                        isInfoSheetPresented = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title)
                            .padding(16)
                            .foregroundStyle(.gray)
                    }
                }
                .offset(x: 85, y: -10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $viewModel.showAppearancePicker) {
                AppearancePickerSheet(
                    selectedAppearance: Binding(
                        get: { viewModel.appearance },
                        set: { viewModel.selectAppearance($0) }
                    )
                )
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $isHelpSheetPresented) {
            HomeSectionsHelpSheet()
        }
        .sheet(isPresented: $isInfoSheetPresented) {
            HomeInfoSheet()
        }
        .preferredColorScheme(viewModel.appearance.colorScheme)
    }
}

private struct HomeSectionsHelpSheet: View {
    @State private var selectedSection: HomeHelpSection = .fullPipeline

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                // Intro
                VStack(alignment: .center, spacing: 20) {
                    Text("What’s in Image Alchemy")
                        .font(.title.weight(.semibold))
                        .fontWidth(.expanded)
                        // .frame(maxWidth: .infinity, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose your path")
                        .font(.title3.weight(.semibold))
                    
                        Text("Each home tile is a different way to understand diffusion models. Use the tabs to see what each one is best for.")
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

                // Segmented control
                Picker("", selection: $selectedSection) {
                    ForEach(HomeHelpSection.all) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)

                // Selected card
                Group {
                    HelpCard(
                        icon: selectedSection.icon,
                        title: selectedSection.title,
                        subtitle: selectedSection.subtitle,
                        description: selectedSection.description,
                        keyPoints: selectedSection.keyPoints
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

private struct HelpCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let keyPoints: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.16))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(keyPoints, id: \.self) { point in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "smallcircle.filled.circle")
                                .font(.system(size: 6, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            Text(point)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct HomeInfoSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSection: HomeInfoSection = .why

    private var iconName: String {
        colorScheme == .dark ? "IconDark" : "IconLight"
    }

    var body: some View {
        VStack(spacing: 24) {
            // Tagline + icon
            VStack(spacing: 12) {
                ZStack {
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 190, height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 50, style: .continuous)
                                .stroke(Color.primary.opacity(0.8), lineWidth: 1)
                        )
                }
                .frame(width: 200, height: 200)
                
                VStack(spacing: 4) {
                    Text("Turning abstract diffusion math")
                        .font(.callout)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    Text("into something you can see, touch, and play with.")
                        .font(.callout)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Developer card
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About the developer")
                                    .font(.subheadline.weight(.semibold))
                                    .textCase(.uppercase)
                            
                            HStack(spacing: 12) {
                                Circle()
                                .fill(Color.orange)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "swift")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)
                                )
                                    
                                
                                Text("I’m Avineet Singh Juneja, a final‑year Computer Science student specializing in AI/ML from India, and a Swift Student Challenge winner 2025.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                    }

                    // Segmented control for info content
                    Picker("", selection: $selectedSection) {
                        ForEach(HomeInfoSection.all) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Segmented content
                    Group {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(selectedSection.title)
                                .font(.headline)
                                .fontWidth(.expanded)

                            Text(selectedSection.intro)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if !selectedSection.keyPoints.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(selectedSection.keyPoints, id: \.self) { point in
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            Image(systemName: "smallcircle.filled.circle")
                                                .font(.system(size: 6, weight: .semibold))
                                                .foregroundStyle(.secondary)

                                            Text(point)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
    }
}

// MARK: - Header Section

private struct HeaderSection: View {
    private var logo: some View {
        Image("Logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Logo from Media.xcassets with glow
            logo
                .cornerRadius(64)
                .blur(radius: 30)
                .offset(y: 10)
                .opacity(0.9)
                .frame(width: 470, height: 470)
                .overlay(logo.frame(width: 470, height: 470))
        }
    }
}

// MARK: - Navigation Cards Section

private struct NavigationCardsSection: View {
    let items: [NavigationItem]

    var body: some View {
        HStack(spacing: 32) {
            ForEach(items) { item in
                HomeNavigationCard(item: item)
                    .frame(width: 350, height: 450)
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Home Navigation Card

/// Card style for home navigation, visually similar to `KnowledgeModeCard`
/// but local to the home screen and simplified for generic destinations.
private struct HomeModeCard<Top: View, Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let animationDelay: Double
    @ViewBuilder let topContent: () -> Top
    @ViewBuilder let destination: () -> Destination

    private let cardCornerRadius: CGFloat = 20
    private let topCornerRadius: CGFloat = 20
    @State private var borderTrim: CGFloat = 0

    var body: some View {
        NavigationLink(destination: destination()) {
            ZStack(alignment: .bottom) {
                topSection
                bottomSection
            }
            // Smooth entrance tied to borderTrim progress
            .opacity(borderTrim)
            .offset(y: (1 - borderTrim) * 24)
            .scaleEffect(0.92 + 0.08 * borderTrim)
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .trim(from: 0, to: borderTrim)
                    .stroke(Color.primary.opacity(0.9), lineWidth: 3.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeOut(duration: 1.4).delay(animationDelay)) {
                borderTrim = 1
            }
        }
    }

    private var topSection: some View {

        topContent()
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
        .frame(height: 100)
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct HomeNavigationCard: View {
    let item: NavigationItem

    private var cardColor: Color { homeCardAccentColor }
    private let borderStepDuration: Double = 1.4
    private let borderStepGap: Double = 0.2

    var body: some View {
        HomeModeCard(
            title: item.title,
            subtitle: item.subtitle,
            icon: item.icon,
            color: cardColor,
            animationDelay: borderAnimationDelay(for: item.destination),
            topContent: {
                topSectionContent()
            }
        ) {
            destinationView(for: item.destination)
        }
    }

    private func borderAnimationDelay(for destination: NavigationItem.Destination) -> Double {
        let step = borderStepDuration + borderStepGap
        switch destination {
        case .fullPipeline:
            return 0
        case .relatedMaths:
            return step
        case .knowledge:
            return step * 2
        }
    }

    @ViewBuilder
    private func topSectionContent() -> some View {
        switch item.destination {
        case .fullPipeline:
            ZStack {
                FullPipelineCardTopSection()
                
                DecoderReconstructionLabStaticPreview()
                    .offset(x: -13, y: -45)
            }

        case .relatedMaths:
            ZStack {
                FullPipelineCardTopSection()

                RelatedMathsChartPreview()
                    .padding(12)
                    .scaleEffect(0.75)
                    .offset(y: -50)
            }

        case .knowledge:
            ZStack {
                FullPipelineCardTopSection()
                KnowledgePreview()
                    // .offset(y: -30)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: NavigationItem.Destination) -> some View {
        switch destination {
        case .fullPipeline:
            FullPipelineView()
        case .relatedMaths:
            RelatedMathsView()
        case .knowledge:
            KnowledgeView()
        }
    }
}

// MARK: - Full Pipeline card top section

/// Dot-grid visual inspired by `FreeformDotsBackground` in `FullPipelineView`,
/// adapted for use inside the home card's top section.
private struct FullPipelineCardTopSection: View {
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
                        context.fill(path, with: .color(.secondary.opacity(0.5)))
                    }
                }
            }
        }
    }
}

// MARK: - Decoder Reconstruction static preview (no animations)

/// Static, non-interactive snapshot of the decoder reconstruction lab
/// used inside the Home full pipeline card.
private struct DecoderReconstructionLabStaticPreview: View {
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 5) {
                HStack(alignment: .center, spacing: 24) {
                    VStack(spacing: 12) {
                        VAEDecoderNodeDiagramPreview(activeLatentIndex: 0)
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
private struct VAEDecoderNodeDiagramPreview: View {
    let activeLatentIndex: Int

    private let latentCount = 4
    private let hiddenCount = 8
    private let pixelCount = 6
    private let nodeRadius: CGFloat = 12

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
                        .stroke(Color.primary.opacity(0.25), lineWidth: 2)
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
                        .stroke(Color.primary.opacity(0.25), lineWidth: 2)
                    }
                }

                // Latent nodes
                ForEach(0..<latentCount, id: \.self) { i in
                    let y = latentSpacing * CGFloat(i + 1)
                    DecoderNetworkNode(isActive: false, color: .cyan, activeScale: 1.0)
                        .position(x: latentX, y: y)
                }

                // Hidden feature nodes
                ForEach(0..<hiddenCount, id: \.self) { j in
                    let y = hiddenSpacing * CGFloat(j + 1)
                    DecoderNetworkNode(isActive: false, color: .cyan, activeScale: 1.0)
                        .position(x: hiddenX, y: y)
                }

                // Pixel feature nodes
                ForEach(0..<pixelCount, id: \.self) { k in
                    let y = pixelSpacing * CGFloat(k + 1)
                    DecoderNetworkNode(isActive: false, color: .cyan, activeScale: 1.0)
                        .position(x: pixelX, y: y)
                }

                // Column labels
                Text("Latent Channels")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .position(x: latentX, y: 10)
                Text("Decoded Features")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .position(x: hiddenX, y: 10)
                Text("Pixel Features")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .position(x: pixelX, y: 10)
            }
        }
    }

}

// MARK: - Related Maths card 3D chart preview

/// Static perspective 3D surface preview for the Related Maths card,
/// inspired by `BivariateGaussianView` but without auto-revolution or controls.
private struct RelatedMathsChartPreview: View {
    @State private var pose = Chart3DPose(
        azimuth: .degrees(40),
        inclination: .degrees(28)
    )

    var body: some View {
        // Fixed Gaussian parameters for a clean bell surface preview
        let mean = 0.0
        let stdDev = 0.40
        let coeff = 1.0 / (2 * .pi * stdDev * stdDev)
        let factor = 1.0 / (2 * stdDev * stdDev)

        return Chart3D {
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
    }
}

// MARK: - Knowledge card preview (home)

/// Sample text preview for the Knowledge home card top section.
private struct KnowledgePreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            HStack {
                FlashcardPreviewVisual(term: "Diffusion", color: knowledgeColor)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -40)

                Spacer()

                QuizPreviewVisual(color: knowledgeColor)
                    .rotationEffect(.degrees(20))
                    .offset(x: 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -30)

            VStack(alignment: .center, spacing: 25) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 70, weight: .semibold))
                    .foregroundStyle(
                        MeshGradient(width: 2, height: 2, points: [
                            [0, 0], [1, 0],
                            [0, 1], [1, 1],
                        ], colors: [
                            .pink, .indigo,
                            .indigo, .blue,
                        ])
                    )
                    .shadow(color: .primary.opacity(0.3), radius: 12, x: 0, y: 4)

                Text("AI Generated flashcards, quiz, and more.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .compositingGroup()
            .offset(y: -30)

            HStack {
                MatchTheFollowingPreviewVisual(color: knowledgeColor)
                    .rotationEffect(.degrees(20))
                    .offset(x: -55)

                Spacer()

                Text("Diffusion")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black.opacity(0.5))
                    // .padding(.horizontal, 10)
                    // .padding(.vertical, 10)
                    .glassEffect(.clear.tint(knowledgeColor), in: .capsule)
                    .shadow(color: knowledgeColor, radius: 12, x: 0, y: 6)
                    .rotationEffect(.degrees(-15))
                    .offset(x: 13, y: -10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .offset(y: -30)
        }
        .drawingGroup()
    }
}

private struct FlashcardPreviewVisual: View {
    let term: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("TERM")
                .font(.system(size: 12, weight: .semibold))
                .fontWidth(.condensed)
                .foregroundStyle(color.opacity(0.9))
            Text(term)
                .font(.system(size: 20, weight: .medium))
                .fontWidth(.expanded)
                .foregroundStyle(.black.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(minWidth: 180, minHeight: 130)
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

private struct QuizPreviewVisual: View {
    let color: Color

    // private static let sampleQuestion = "What does the forward process do?"
    private static let sampleOptions = ["Adds noise", "Removes noise", "Compresse images"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Text(Self.sampleQuestion)
            //     .font(.system(size: 14, weight: .semibold, design: .rounded))
            //     .foregroundStyle(.primary.opacity(0.9))
            //     .lineLimit(2)

            VStack(spacing: 8) {
                ForEach(Array(Self.sampleOptions.enumerated()), id: \.offset) { index, option in
                    HStack(spacing: 10) {
                        Text(optionLabel(for: index))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(color)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(color.opacity(0.2)))
                        Text(option)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.primary.opacity(0.85))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.2))
                    )
                }
            }
        }
        // .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                                .background(Circle().fill(color))
                            Text(item.text)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.85))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
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
                                RoundedRectangle(cornerRadius: 12)
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

// MARK: - Knowledge card preview (modes)

/// Compact preview of the four knowledge modes (Flashcards, Quiz, Match, Fill)
/// shown in the top section of the Knowledge home card.
private struct KnowledgeModesPreview: View {
    let term: String

    var body: some View {
        VStack(spacing: 8) {
            Text("TERM")
                .font(.system(size: 14, weight: .semibold))
                .fontWidth(.condensed)
                .foregroundStyle(knowledgeColor.opacity(0.9))
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
                        .stroke(knowledgeColor.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Appearance Toggle

private struct AppearanceToggle: View {
    let currentAppearance: AppAppearance
    let onCycle: () -> Void
    let onShowPicker: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Quick cycle button
            Button(action: onCycle) {
                HStack(spacing: 8) {
                    Image(systemName: currentAppearance.icon)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(currentAppearance.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)
            
            // More options button
            Button(action: onShowPicker) {
                Image(systemName: "chevron.up.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Appearance Picker Sheet

private struct AppearancePickerSheet: View {
    @Binding var selectedAppearance: AppAppearance
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose Appearance")
                    .font(.headline)
                    .padding(.top)
                
                HStack(spacing: 16) {
                    ForEach(AppAppearance.allCases) { appearance in
                        AppearanceOption(
                            appearance: appearance,
                            isSelected: selectedAppearance == appearance
                        ) {
                            selectedAppearance = appearance
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(selectedAppearance.colorScheme)
    }
}

// MARK: - Appearance Option

private struct AppearanceOption: View {
    let appearance: AppAppearance
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Preview box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appearance.previewBackgroundColor)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: appearance.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(appearance.previewForegroundColor)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                
                // Label
                Text(appearance.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
}
