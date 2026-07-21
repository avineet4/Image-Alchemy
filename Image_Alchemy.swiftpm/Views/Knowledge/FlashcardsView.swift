import SwiftUI

struct FlashcardsView: View {
    @Bindable var viewModel: FlashcardsViewModel
    
    @State private var cardDragOffset: CGFloat = 0
    @State private var cardOpacity: Double = 1
    
    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isGenerating && viewModel.flashcards.isEmpty {
                FlashcardsGeneratingView(generationSteps: viewModel.generationSteps)
                    .frame(maxHeight: .infinity)
            } else if !viewModel.flashcards.isEmpty {
                VStack(spacing: 20) {
                    KnowledgeProgressIndicator(
                        currentIndex: viewModel.currentIndex,
                        totalCount: viewModel.flashcards.count,
                        labelFormat: { "Card \($0) of \($1)" },
                        activeColor: knowledgeAccentColor,
                        dotColor: { index in
                            index == viewModel.currentIndex
                            ? knowledgeAccentColor
                            : Color.secondary.opacity(0.3)
                        }
                    )
                    
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 50) {
                        FlashcardNavButton(
                            title: "Previous",
                            systemImage: "chevron.left",
                            isEnabled: viewModel.canGoPrevious,
                            isLeading: true,
                            action: {
                                guard viewModel.canGoPrevious else { return }
                                swipeToCard(direction: 1) {
                                    viewModel.goToPrevious()
                                }
                            }
                        )
                        
                        if let card = viewModel.currentCard {
                            FlipCardView(
                                term: card.term,
                                definition: card.definition,
                                isFlipped: $viewModel.isFlipped,
                                color: knowledgeAccentColor
                            )
                            .scaleEffect(1.08)
                            .offset(x: cardDragOffset)
                            .opacity(cardOpacity)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onChanged { value in
                                        let horizontal = value.translation.width
                                        let vertical = abs(value.translation.height)
                                        
                                        // Only react to mostly-horizontal drags
                                        guard abs(horizontal) > vertical else {
                                            cardDragOffset = 0
                                            return
                                        }
                                        
                                        // Slightly damp the drag movement
                                        cardDragOffset = horizontal * 0.6
                                    }
                                    .onEnded { value in
                                        let horizontal = value.translation.width
                                        let vertical = abs(value.translation.height)
                                        
                                        // Only react to mostly-horizontal swipes
                                        guard abs(horizontal) > vertical else {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                cardDragOffset = 0
                                            }
                                            return
                                        }
                                        
                                        let threshold: CGFloat = 60
                                        
                                        if horizontal < -threshold,
                                           viewModel.canGoNext {
                                            swipeToCard(direction: -1) {
                                                viewModel.goToNext()
                                            }
                                        } else if horizontal > threshold,
                                                  viewModel.canGoPrevious {
                                            swipeToCard(direction: 1) {
                                                viewModel.goToPrevious()
                                            }
                                        } else {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                cardDragOffset = 0
                                            }
                                        }
                                    }
                            )
                        }
                        
                        FlashcardNavButton(
                            title: "Next",
                            systemImage: "chevron.right",
                            isEnabled: viewModel.canGoNext,
                            isLeading: false,
                            action: {
                                guard viewModel.canGoNext else { return }
                                swipeToCard(direction: -1) {
                                    viewModel.goToNext()
                                }
                            }
                        )
                    }
                        .scaleEffect(1.08)
                    
                    Spacer()
                    
                    Text("Tap the card to flip")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            } else {
                VStack(spacing: 12) {
                    FlashcardsEmptyStateView()
                        .frame(maxHeight: .infinity)
                    
                    if let error = viewModel.generationError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Show reset only once a full set of cards has been generated.
                // Only show reset when we actually have cards (not in empty state) and we're not generating
                if !viewModel.isGenerating && !viewModel.flashcards.isEmpty {
                    Button {
                        // Reset to empty state
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                            cardDragOffset = 0
                            cardOpacity = 1
                            viewModel.flashcards = []
                            viewModel.generationSteps = []
                            viewModel.currentIndex = 0
                            viewModel.isFlipped = false
                            viewModel.generationError = nil
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                
                Button {
                    Task {
                        await viewModel.generateFlashcardsWithAI(forceRefresh: true)
                    }
                } label: {
                    if viewModel.isGenerating {
                        ProgressView()
                    } else {
                        Text("Generate with AI")
                            .fontWeight(.semibold)
                    }
                }
                .tint(knowledgeAccentColor)
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isGenerating)
            }
        }
    }
}

private struct FlashcardsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .foregroundStyle(knowledgeAccentColor)
                .symbolEffect(.pulse.byLayer, options: .repeating)
            
            VStack(spacing: 4) {
                Text("No flashcards yet")
                    .font(.title.weight(.semibold))
                
                Text("Generate AI-powered flashcards to review key diffusion concepts from Image Alchemy.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Label("Based on your Image Alchemy walkthrough", systemImage: "sparkles")
                Label("Covers terminology, intuition, and equations", systemImage: "brain.head.profile")
                Label("Perfect for quick study sessions", systemImage: "clock.badge.checkmark")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 420, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FlashcardsGeneratingView: View {
    let generationSteps: [GenerationStep]
    @State private var show = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            MeshGradient(width: 2, height: 2, points: [
                                [0, 0], [1, 0],
                                [0, 1], [1, 1],
                            ], colors: [
                                .pink, .indigo,
                                .indigo, .blue,
                            ])
                        )
                    Text(.init("Generating flashcards for **Image Alchemy**..."))
                        .font(.system(size: 34, weight: .bold))
                        .fontWidth(.expanded)
                        .opacity(show ? 1 : 0)
                }
            }
            
            if !generationSteps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(generationSteps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: step.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(knowledgeAccentColor)
                                .frame(width: 32, alignment: .leading)
                            Text(.init(step.message))
                                .font(.body)
                                .italic()
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.96)),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(Double(index) * 0.06), value: generationSteps.count)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: generationSteps.count)
        .symbolEffect(.breathe, isActive: true)
        .padding(.horizontal, 40)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                show = true
            }
        }
    }
}

private struct FlashcardNavButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let isLeading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(isEnabled ? Color.accentColor : Color.secondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                )
                .opacity(isEnabled ? 1.0 : 0.3)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Private animation helpers

private extension FlashcardsView {
    // Animate the current card swiping out in the given direction, update the index,
    func swipeToCard(direction: CGFloat, performChange: @escaping () -> Void) {
        let outOffset: CGFloat = direction * 400
        let inOffset: CGFloat = -direction * 400
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            cardDragOffset = outOffset
            cardOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            performChange()
            cardDragOffset = inOffset
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                cardDragOffset = 0
                cardOpacity = 1.0
            }
        }
    }
}

#Preview("Empty state") {
    NavigationStack {
        FlashcardsView(viewModel: FlashcardsViewModel())
    }
}

#Preview("With sample flashcards") {
    NavigationStack {
        FlashcardsView(viewModel: FlashcardsViewModel(flashcards: Flashcard.sampleFlashcards))
    }
}
