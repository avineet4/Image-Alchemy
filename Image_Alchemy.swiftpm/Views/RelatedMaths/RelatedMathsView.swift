import SwiftUI

struct RelatedMathsView: View {
    @State private var viewModel: RelatedMathsViewModel

    init(viewModel: RelatedMathsViewModel? = nil, initialTopic: MathTopic? = nil) {
        _viewModel = State(initialValue: viewModel ?? RelatedMathsViewModel(initialTopic: initialTopic))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationSplitView {
            sidebar(viewModel: viewModel)
        } detail: {
            detailContent(viewModel: viewModel)
        }
    }

    // MARK: - Sidebar

    private func sidebar(viewModel: RelatedMathsViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return List(selection: $viewModel.expandedTopic) {
            Section("Topics") {
                ForEach(viewModel.topics) { topic in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(topic.color.opacity(0.18))
                                .frame(width: 34, height: 34)
                            
                            Image(systemName: topic.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(topic.color)
                        }
                        
                        Text(topic.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.primary)
                        
                        Spacer()
                    }
                    .tag(topic)
                }
            }
        }
        .listStyle(.sidebar)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Detail

    @ViewBuilder
    private func detailContent(viewModel: RelatedMathsViewModel) -> some View {
        @Bindable var viewModel = viewModel
        let selectedTopic = viewModel.expandedTopic ?? viewModel.topics.first
        
        if let topic = selectedTopic {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        RichText(text: topic.title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                        
                        Text(viewModel.headerDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Equation / visualization container
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            // Topic subtitle / quick blurb
                            RichText(text: topic.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            topicContent(for: topic, viewModel: viewModel)
                        }
                        .padding(4)
                    }
                    .groupBoxStyle(.automatic)
                    
                    Spacer(minLength: 0)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
        } else {
            VStack(spacing: 12) {
                Image(systemName: "function")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                
                Text("Choose a topic from the sidebar")
                    .font(.headline)
                
                Text("Browse the maths behind diffusion models, just like picking a show in the TV app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    @ViewBuilder
    private func topicContent(for topic: MathTopic, viewModel: RelatedMathsViewModel) -> some View {
        @Bindable var viewModel = viewModel
        switch topic {
        case .probabilityBasics:
            ProbabilityBasicsView()
            
        case .randomVariables:
            RandomVariablesView()
            
        case .vectorsAndDotProduct:
            VectorsAndDotProductView()
            
        case .gaussian:
            VStack(alignment: .leading, spacing: 16) {
                Picker("View", selection: $viewModel.gaussianViewMode) {
                    ForEach(RelatedMathsViewModel.GaussianViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ZStack {
                    BivariateGaussianView(
                        mean: $viewModel.gaussianMean,
                        stdDev: $viewModel.gaussianStdDev
                    )
                    .opacity(viewModel.gaussianViewMode == .threeD ? 1 : 0)
                    .allowsHitTesting(viewModel.gaussianViewMode == .threeD)

                    GaussianDistributionView(
                        mean: $viewModel.gaussianMean,
                        stdDev: $viewModel.gaussianStdDev
                    )
                    .opacity(viewModel.gaussianViewMode == .twoD ? 1 : 0)
                    .allowsHitTesting(viewModel.gaussianViewMode == .twoD)
                }
            }
            
        case .noiseSchedule:
            NoiseScheduleView(
                currentTimestep: $viewModel.currentTimestep,
                totalTimesteps: viewModel.totalTimesteps,
                betaMin: viewModel.betaMin,
                betaMax: viewModel.betaMax,
                betaAt: viewModel.betaAt,
                alphaBarAt: viewModel.alphaBarAt
            )
            
        case .forwardEquation:
            ForwardEquationView(
                timestep: $viewModel.forwardTimestep,
                selectedPart: $viewModel.selectedForwardPart,
                signalWeight: viewModel.forwardSignalWeight,
                noiseWeight: viewModel.forwardNoiseWeight,
                totalTimesteps: viewModel.totalTimesteps,
                alphaBarAt: { viewModel.alphaBarAt(timestep: $0) }
            )
            
        case .reverseEquation:
            ReverseEquationView(
                selectedPart: $viewModel.selectedReversePart,
                animationStep: $viewModel.reverseAnimationStep,
                onAdvanceAnimation: viewModel.advanceReverseAnimation
            )
            
        case .lossFunction:
            VStack(alignment: .leading, spacing: 16) {
                Picker("View", selection: $viewModel.lossViewMode) {
                    ForEach(RelatedMathsViewModel.LossViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ZStack {
                    LossFunctionView(
                        isAnimating: $viewModel.isTrainingAnimating,
                        currentLoss: $viewModel.currentLoss,
                        onStartTraining: viewModel.startTrainingAnimation,
                        onStopTraining: viewModel.stopTrainingAnimation,
                        onReset: viewModel.resetTraining
                    )
                    .opacity(viewModel.lossViewMode == .trainingSim ? 1 : 0)
                    .allowsHitTesting(viewModel.lossViewMode == .trainingSim)

                    LossLandscapeView(
                        ruggedness: $viewModel.lossLandscapeRuggedness,
                        style: $viewModel.lossLandscapeStyle,
                        usePerspective: $viewModel.lossLandscapePerspective
                    )
                        .opacity(viewModel.lossViewMode == .landscape3D ? 1 : 0)
                        .allowsHitTesting(viewModel.lossViewMode == .landscape3D)
                }
            }

        case .latentSpace:
            LatentSpaceView()
        }
    }
}
