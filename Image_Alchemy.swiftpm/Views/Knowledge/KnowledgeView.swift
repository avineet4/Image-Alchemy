import SwiftUI

// Shared accent color for Knowledge mode views (Flashcards, Quiz, Match the Following).
let knowledgeAccentColor = Color(red: 0.56, green: 0.49, blue: 0.43)

struct KnowledgeView: View {
    @EnvironmentObject private var knowledgeSession: KnowledgeSession
    @State private var isKnowledgeHelpSheetPresented = false
    @State private var hasAppeared = false

    private let knowledgeCardColor = knowledgeAccentColor
    private let cardSpacing: CGFloat = 20
    private let horizontalPadding: CGFloat = 24
    private let subtitleText = "Choose a mode to practice diffusion model concepts"

    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height >= geometry.size.width
            let availableWidth = geometry.size.width - (horizontalPadding * 2) - (cardSpacing * 3)
            let rawCardWidth = availableWidth / 4
            let minimumCardWidth: CGFloat = 180
            let cardWidth = max(minimumCardWidth, rawCardWidth)
            let cardHeight = geometry.size.height * 0.52

            VStack(spacing: 0) {
                Spacer().frame(height: 40)
                modesSection(isPortrait: isPortrait, cardWidth: cardWidth, cardHeight: cardHeight)
                Spacer(minLength: 40)
            }
            .padding(horizontalPadding)
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Test Your Knowledge")
        .navigationSubtitle(subtitleText)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isKnowledgeHelpSheetPresented = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title)
                        .foregroundStyle(.gray)
                }
            }
        }
        .sheet(isPresented: $isKnowledgeHelpSheetPresented) {
            KnowledgeHelpSheet()
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                hasAppeared = true
            }
        }
        .task {
            await FlashcardGenerator.shared.prewarm()
        }
    }
    
    private func modesSection(isPortrait: Bool, cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        Group {
            if isPortrait {
                // Portrait: show modes in a 2x2 grid
                let columns = [
                    GridItem(.flexible(), spacing: cardSpacing),
                    GridItem(.flexible(), spacing: cardSpacing)
                ]
                
                LazyVGrid(columns: columns, spacing: cardSpacing) {
                    KnowledgeModeCard(
                        title: "Flashcards",
                        subtitle: "Flip through cards to review terms and definitions",
                        icon: "rectangle.stack.fill",
                        color: knowledgeCardColor
                    ) {
                        FlashcardsView(viewModel: knowledgeSession.flashcardsViewModel)
                    }
                    .frame(height: cardHeight * 0.85)
                    
                    KnowledgeModeCard(
                        title: "Match the Following",
                        subtitle: "Pair items from two columns correctly",
                        icon: "arrow.left.arrow.right",
                        color: knowledgeCardColor
                    ) {
                        MatchTheFollowingView(viewModel: knowledgeSession.matchTheFollowingViewModel)
                    }
                    .frame(height: cardHeight * 0.85)
                    
                    KnowledgeModeCard(
                        title: "Quiz",
                        subtitle: "Answer multiple-choice questions",
                        icon: "checkmark.circle.fill",
                        color: knowledgeCardColor
                    ) {
                        QuizView(viewModel: knowledgeSession.quizViewModel)
                    }
                    .frame(height: cardHeight * 0.85)
                    
                    KnowledgeModeCard(
                        title: "Fill in the Blanks",
                        subtitle: "Complete sentences with missing terms",
                        icon: "pencil.line",
                        color: knowledgeCardColor
                    ) {
                        FillInTheBlanksView(viewModel: knowledgeSession.fillInTheBlanksViewModel)
                    }
                    .frame(height: cardHeight * 0.85)
                }
            } else {
                // Landscape: keep original horizontal layout
                HStack(spacing: cardSpacing) {
                    KnowledgeModeCard(
                        title: "Flashcards",
                        subtitle: "Flip through cards to review terms and definitions",
                        icon: "rectangle.stack.fill",
                        color: knowledgeCardColor
                    ) {
                        FlashcardsView(viewModel: knowledgeSession.flashcardsViewModel)
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    
                    KnowledgeModeCard(
                        title: "Match the Following",
                        subtitle: "Pair items from two columns correctly",
                        icon: "arrow.left.arrow.right",
                        color: knowledgeCardColor
                    ) {
                        MatchTheFollowingView(viewModel: knowledgeSession.matchTheFollowingViewModel)
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    
                    KnowledgeModeCard(
                        title: "Quiz",
                        subtitle: "Answer multiple-choice questions",
                        icon: "checkmark.circle.fill",
                        color: knowledgeCardColor
                    ) {
                        QuizView(viewModel: knowledgeSession.quizViewModel)
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    
                    KnowledgeModeCard(
                        title: "Fill in the Blanks",
                        subtitle: "Complete sentences with missing terms",
                        icon: "pencil.line",
                        color: knowledgeCardColor
                    ) {
                        FillInTheBlanksView(viewModel: knowledgeSession.fillInTheBlanksViewModel)
                    }
                    .frame(width: cardWidth, height: cardHeight)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Knowledge help sheet (on-device model info)
private struct KnowledgeHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    KnowledgeHelpCard(
                        icon: "cpu",
                        title: "On-Device Foundation Model",
                        description: "In this section, an on-device foundation model is used to generate flashcards, quiz questions, and more.",
                        items: ["Flashcards", "Quiz", "Match the Following", "Fill in the Blanks"]
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct KnowledgeHelpCard: View {
    let icon: String
    let title: String
    let description: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(knowledgeAccentColor.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(knowledgeAccentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What it powers")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    FlowLayout(spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(knowledgeAccentColor.opacity(0.12), in: Capsule())
                                .foregroundStyle(knowledgeAccentColor)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        KnowledgeView()
            .environmentObject(KnowledgeSession())
    }
}
