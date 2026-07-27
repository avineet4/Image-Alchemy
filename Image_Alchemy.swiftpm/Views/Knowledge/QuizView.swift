import SwiftUI

struct QuizView: View {
    @Bindable var viewModel: QuizViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isGenerating && viewModel.questions.isEmpty {
                QuizGeneratingView(generationSteps: viewModel.generationSteps)
                    .frame(maxHeight: .infinity)
            } else if viewModel.questions.isEmpty {
                // Empty state (no questions yet, not currently generating)
                QuizEmptyStateView(isGenerating: viewModel.isGenerating, error: viewModel.generationError)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Normal quiz flow when we have questions
                KnowledgeProgressIndicator(
                    currentIndex: viewModel.currentIndex,
                    totalCount: viewModel.questions.count,
                    labelFormat: { "Question \($0) of \($1)" },
                    activeColor: knowledgeAccentColor,
                    dotColor: { viewModel.dotColor(for: $0) }
                )
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let question = viewModel.currentQuestion {
                            questionCard(question)
                            optionsSection(question)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                
                StepNavigationButtons(
                    canGoPrevious: viewModel.canGoPrevious,
                    canGoNext: viewModel.canGoNext,
                    onPrevious: { viewModel.goToPrevious() },
                    onNext: { viewModel.goToNext() }
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Show reset only when we have questions and we're not generating
                if !viewModel.isGenerating && !viewModel.questions.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                            viewModel.questions = []
                            viewModel.selectedAnswers = []
                            viewModel.currentIndex = 0
                            viewModel.generationError = nil
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                
                Button {
                    Task {
                        await viewModel.generateQuizWithAI(forceRefresh: true)
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
    
    private func questionCard(_ question: QuizQuestion) -> some View {
        Text(question.question)
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
    }
    
    private func optionsSection(_ question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                QuizOptionButton(
                    option: option,
                    optionLabel: String(UnicodeScalar(65 + index)!),
                    isSelected: viewModel.isOptionSelected(index),
                    isCorrect: question.correctIndex == index,
                    showFeedback: viewModel.hasAnsweredCurrent
                ) {
                    viewModel.selectOption(index)
                }
            }
        }
    }
}

private struct QuizEmptyStateView: View {
    let isGenerating: Bool
    let error: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.badge.questionmark")
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .foregroundStyle(knowledgeAccentColor)
                .symbolEffect(.pulse.byLayer, options: .repeating)
            
            VStack(spacing: 4) {
                Text(isGenerating ? "Generating quiz…" : "No quiz yet")
                    .font(.title.weight(.semibold))
                
                Text(isGenerating
                     ? "Crafting multiple-choice questions from your Image Alchemy walkthrough."
                     : "Generate a quiz with Apple Intelligence to test your diffusion knowledge.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 6) {
                Label("Based on your Image Alchemy walkthrough", systemImage: "sparkles")
                Label("Multiple-choice questions with instant feedback", systemImage: "checkmark.circle")
                Label("Great for exam-style practice", systemImage: "graduationcap.fill")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 420, alignment: .leading)
            
            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

private struct QuizGeneratingView: View {
    let generationSteps: [GenerationStep]
    @State private var show = false
    @State private var showSteps = false
    
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
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                    Text(.init("Generating quiz for **Image Alchemy**..."))
                        .font(.system(size: 34, weight: .bold))
                        .fontWidth(.expanded)
                        .opacity(show ? 1 : 0)
                }
            }
            
            if !generationSteps.isEmpty && showSteps {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(generationSteps.enumerated()), id: \.element.id) { index, step in
                        KnowledgeGenerationStepRow(step: step, index: index, stepCount: generationSteps.count)
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
        .padding(.horizontal, 40)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                show = true
            }
            // Delay showing steps after header appears
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
                withAnimation(.easeIn(duration: 0.3)) {
                    showSteps = true
                }
            }
        }
    }
    
}

#Preview("Empty State") {
    NavigationStack {
        QuizView(viewModel: QuizViewModel())
    }
}

#Preview("With sample questions") {
    NavigationStack {
        QuizView(viewModel: QuizViewModel(questions: QuizQuestion.sampleQuestions))
    }
}
