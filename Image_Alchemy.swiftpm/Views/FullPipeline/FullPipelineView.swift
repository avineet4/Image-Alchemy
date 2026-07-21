import SwiftUI

// Full pipeline: Architecture overview only.
struct FullPipelineView: View {
    @State private var viewModel: FullPipelineViewModel
    @State private var forwardProcessDragOffset: CGSize = .zero
    @State private var forwardProcessDragAccumulatedOffset: CGSize = .zero
    @State private var reverseProcessDragOffset: CGSize = .zero
    @State private var reverseProcessDragAccumulatedOffset: CGSize = .zero
    @State private var conditioningDragOffset: CGSize = .zero
    @State private var conditioningDragAccumulatedOffset: CGSize = .zero

    init(viewModel: FullPipelineViewModel = FullPipelineViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        let selectedComponentBinding: Binding<ModelComponent> =
            viewModel.currentScreen == .forwardProcess
            ? .constant(.diffusionProcess)
            : $viewModel.selectedComponent
        ZStack {
            FreeformDotsBackground()
                .ignoresSafeArea()

            architectureOverviewContent(selectedComponent: $viewModel.selectedComponent)
            .navigationTitle("Architecture Overview")
            .navigationSubtitle("End-to-end diffusion pipeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarSpacer(.flexible)

                if viewModel.shouldShowResetArchitectureButton {
                    ToolbarItem {
                        Button {
                            withAnimation(.smooth(duration: 0.2)) {
                                viewModel.resetArchitectureView()
                                forwardProcessDragOffset = .zero
                                forwardProcessDragAccumulatedOffset = .zero
                                reverseProcessDragOffset = .zero
                                reverseProcessDragAccumulatedOffset = .zero
                                conditioningDragOffset = .zero
                                conditioningDragAccumulatedOffset = .zero
                            }
                        } label: {
                            Label("Reset architecture scale", systemImage: "arrow.counterclockwise")
                        }
                    }

                    ToolbarSpacer(.fixed)
                }

                ToolbarItem {
                    HStack(spacing: 6) {
                        Button {
                            viewModel.decreaseArchitectureScale()
                        } label: {
                            Label("Minimize architecture", systemImage: "minus")
                        }
                        .disabled(!viewModel.canDecreaseArchitectureScale)

                        Text("\(Int(viewModel.architectureScale * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 36, alignment: .center)

                        Button {
                            viewModel.increaseArchitectureScale()
                        } label: {
                            Label("Maximize architecture", systemImage: "plus")
                        }
                        .disabled(!viewModel.canIncreaseArchitectureScale)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }

                ToolbarSpacer(.fixed)

                ToolbarItem {
                    StepNavigationButtons(
                        canGoPrevious: viewModel.canGoPreviousScreen,
                        canGoNext: viewModel.canGoNextScreen,
                        onPrevious: { viewModel.previousScreen() },
                        onNext: { viewModel.nextScreen() }
                    )
                    .controlSize(.small)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ExpandableBottomSheet(
                        selectedComponent: selectedComponentBinding,
                        isExpanded: $viewModel.isInfoSheetExpanded,
                        showVAEContent: viewModel.currentScreen == .latentSpace || viewModel.currentScreen == .forwardDiffusionLab,
                        latentLabSheetMode: {
                            switch viewModel.currentScreen {
                            case .latentSpace:
                                return latentLabSheetMode(from: viewModel.latentLabSelectedArea)
                            case .forwardDiffusionLab:
                                return .latentGrid
                            default:
                                return nil
                            }
                        }(),
                        showReverseDiffusionContent: viewModel.currentScreen == .reverseProcess,
                        showConditioningContent: viewModel.currentScreen == .conditioningAndGuidance,
                        conditioningLabSheetMode: viewModel.currentScreen == .conditioningAndGuidance ? conditioningLabSheetMode(from: viewModel.conditioningLabSelectedArea) : nil
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .ignoresSafeArea()
        }
    }

    // Maps Latent Space lab selection to bottom sheet content mode.
    private func latentLabSheetMode(from area: FullPipelineViewModel.LatentLabArea?) -> LatentLabSheetMode {
        switch area {
        case .pixelImage: return .trainingDataEncoder
        case .latentGrid: return .latentGrid
        case nil: return .vaeOverview
        }
    }

    // Maps Conditioning & Guidance lab selection to bottom sheet content mode.
    private func conditioningLabSheetMode(from area: FullPipelineViewModel.ConditioningLabArea?) -> ConditioningLabSheetMode {
        switch area {
        case .embeddings: return .embeddings
        case .noisyLatent: return .noisyLatent
        case .unet: return .unet
        case .noisePrediction: return .noisePrediction
        case nil: return .overview
        }
    }
    
    // MARK: - Phase 0: Architecture Overview

    @ViewBuilder
    private func architectureOverviewContent(selectedComponent: Binding<ModelComponent>) -> some View {
        switch viewModel.currentScreen {
        case .overview:
            VStack(spacing: 24) {
                UnifiedArchitectureView(
                    highlightedComponents: viewModel.overviewHighlightedComponents,
                    flowDirection: viewModel.overviewFlowDirection,
                    conditioningText: viewModel.conditioningText,
                    selectedComponent: selectedComponent,
                    onLatentGridTap: {
                        viewModel.selectedComponent = .latent
                    }
                )
                .scaleEffect(viewModel.architectureScale)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .offset(viewModel.overviewDragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        viewModel.updateOverviewDrag(translation: value.translation)
                    }
                    .onEnded { _ in
                        viewModel.commitOverviewDrag()
                    }
            )

        case .latentSpace:
            LatentSpaceLabView(
                scale: viewModel.architectureScale,
                selectedArea: $viewModel.latentLabSelectedArea
            )

        case .forwardDiffusionLab:
            ForwardDiffusionLatentGridSection(scale: viewModel.architectureScale)

        case .forwardProcess:
            ForwardDiffusionLabView()
                .scaleEffect(viewModel.architectureScale * 0.75)
                .offset(forwardProcessDragOffset)
                .offset(y: -80)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            forwardProcessDragOffset = CGSize(
                                width: forwardProcessDragAccumulatedOffset.width + value.translation.width,
                                height: forwardProcessDragAccumulatedOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            forwardProcessDragAccumulatedOffset = forwardProcessDragOffset
                        }
                )

        case .reverseProcess:
            ReverseDiffusionLabView()
                .scaleEffect(viewModel.architectureScale * 0.75)
                .offset(reverseProcessDragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            reverseProcessDragOffset = CGSize(
                                width: reverseProcessDragAccumulatedOffset.width + value.translation.width,
                                height: reverseProcessDragAccumulatedOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            reverseProcessDragAccumulatedOffset = reverseProcessDragOffset
                        }
                )
        case .decoderLab:
            DecoderReconstructionLabView(
                scale: viewModel.architectureScale,
                onSelectLatentPanel: {
                    viewModel.selectedComponent = .latent
                },
                onSelectImagePanel: {
                    viewModel.selectedComponent = .generatedImage
                },
                onSelectDecoderPanel: {
                    viewModel.selectedComponent = .decoder
                }
            )
            .offset(y: 53)

        case .conditioningAndGuidance:
            ConditioningAndGuidanceLabView(
                prompt: $viewModel.conditioningText,
                guidanceScale: $viewModel.guidanceScale,
                architectureScale: viewModel.architectureScale,
                selectedArea: $viewModel.conditioningLabSelectedArea
            )
            .scaleEffect(viewModel.architectureScale * 0.50)
            .offset(conditioningDragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        conditioningDragOffset = CGSize(
                            width: conditioningDragAccumulatedOffset.width + value.translation.width,
                            height: conditioningDragAccumulatedOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        conditioningDragAccumulatedOffset = conditioningDragOffset
                    }
            )
        }
    }
}

// Dotted background inspired by Freeform.
private struct FreeformDotsBackground: View {
    private let baseColor = Color(.systemGroupedBackground)
    private let dotColor = Color.primary.opacity(0.14)
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            Canvas { context, _ in
                let spacing: CGFloat = 32
                let radius: CGFloat = 2
                
                for row in stride(from: 0 as CGFloat, through: size.height + spacing, by: spacing) {
                    for column in stride(from: 0 as CGFloat, through: size.width + spacing, by: spacing) {
                        let x = column
                        let y = row
                        
                        let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                        let path = Path(ellipseIn: rect)
                        context.fill(path, with: .color(dotColor))
                    }
                }
            }
            .background(baseColor)
        }
    }
}

