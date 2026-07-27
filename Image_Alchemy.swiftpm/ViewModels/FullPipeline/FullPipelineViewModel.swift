import SwiftUI

// ViewModel for the Full Pipeline (architecture overview + linked component views).
@MainActor
@Observable
final class FullPipelineViewModel {

    // MARK: - Properties
    
    var conditioningText: String = "A tropical beach with white sand"
    
    var guidanceScale: Double = 7.0

    // MARK: - High-level pipeline screens (overview ↔ component views)

    enum Screen: Int, CaseIterable {
        case overview
        case latentSpace
        case forwardDiffusionLab
        case forwardProcess
        case reverseProcess
        case decoderLab
        case conditioningAndGuidance
    }

    enum LatentLabArea {
        case pixelImage
        case latentGrid
    }

    enum ConditioningLabArea {
        case embeddings
        case noisyLatent
        case unet
        case noisePrediction
    }

    var currentScreen: Screen = .overview

    var latentLabSelectedArea: LatentLabArea? = nil

    var conditioningLabSelectedArea: ConditioningLabArea? = nil

    var architectureOverviewStepIndex: Int = 0
    
    var isInfoSheetExpanded: Bool = false

    var selectedComponent: ModelComponent = .whatIsDiffusion

    // MARK: - Architecture Overview Interaction (pan/zoom)

    var overviewDragOffset: CGSize = .zero

    var overviewDragAccumulatedOffset: CGSize = .zero

    var architectureScale: CGFloat = 1.35

    static let defaultArchitectureScale: CGFloat = 1.35
    static let minArchitectureScale: CGFloat = 0.6
    static let maxArchitectureScale: CGFloat = 2.0
    static let architectureScaleStep: CGFloat = 0.2

    let architectureOverviewSteps = ArchitectureOverviewStep.allSteps

    init() {
        syncSelectedComponentToCurrentStep()
    }
    
    // MARK: - Architecture Overview
    
    var currentOverviewStep: ArchitectureOverviewStep {
        architectureOverviewSteps[architectureOverviewStepIndex]
    }
    
    var overviewFlowDirection: DiffusionFlowDirection {
        let step = currentOverviewStep
        if step.highlightForward != nil && step.highlightReverse == nil {
            return .forward
        } else if step.highlightReverse != nil && step.highlightForward == nil {
            return .reverse
        } else {
            return .neutral
        }
    }
    
    var canGoPreviousOverview: Bool {
        architectureOverviewStepIndex > 0
    }
    
    var canGoNextOverview: Bool {
        architectureOverviewStepIndex < architectureOverviewSteps.count - 1
    }
    
    var overviewHighlightedComponents: Set<UnifiedArchitectureComponent> {
        currentOverviewStep.highlightedUnifiedComponents
    }
    
    var canGoPreviousScreen: Bool {
        currentScreen.rawValue > Screen.allCases.startIndex
    }
    
    var canGoNextScreen: Bool {
        currentScreen.rawValue < Screen.allCases.endIndex - 1
    }
    
    // MARK: - Actions
    
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if canGoNextOverview {
                architectureOverviewStepIndex += 1
            }
            syncSelectedComponentToCurrentStep()
        }
    }
    
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if canGoPreviousOverview {
                architectureOverviewStepIndex -= 1
            }
            syncSelectedComponentToCurrentStep()
        }
    }

    // MARK: - Architecture Overview Pan/Zoom

    func updateOverviewDrag(translation: CGSize) {
        overviewDragOffset = CGSize(
            width: overviewDragAccumulatedOffset.width + translation.width,
            height: overviewDragAccumulatedOffset.height + translation.height
        )
    }

    func commitOverviewDrag() {
        overviewDragAccumulatedOffset = overviewDragOffset
    }

    func resetArchitectureView() {
        withAnimation(.smooth(duration: 0.2)) {
            architectureScale = Self.defaultArchitectureScale
            overviewDragOffset = .zero
            overviewDragAccumulatedOffset = .zero
        }
    }

    func decreaseArchitectureScale() {
        withAnimation(.smooth(duration: 0.2)) {
            architectureScale = max(Self.minArchitectureScale, architectureScale - Self.architectureScaleStep)
        }
    }

    func increaseArchitectureScale() {
        withAnimation(.smooth(duration: 0.2)) {
            architectureScale = min(Self.maxArchitectureScale, architectureScale + Self.architectureScaleStep)
        }
    }

    var canDecreaseArchitectureScale: Bool { architectureScale > Self.minArchitectureScale }
    var canIncreaseArchitectureScale: Bool { architectureScale < Self.maxArchitectureScale }

    var shouldShowResetArchitectureButton: Bool {
        architectureScale != Self.defaultArchitectureScale || overviewDragAccumulatedOffset != .zero
    }

    // MARK: - Screen-level navigation

    func nextScreen() {
        guard canGoNextScreen else { return }
        if let next = Screen(rawValue: currentScreen.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                if currentScreen == .latentSpace { latentLabSelectedArea = nil }
                if currentScreen == .conditioningAndGuidance { conditioningLabSelectedArea = nil }
                currentScreen = next
                if next == .decoderLab {
                    selectedComponent = .decoder
                }
            }
        }
    }

    func previousScreen() {
        guard canGoPreviousScreen else { return }
        if let previous = Screen(rawValue: currentScreen.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                if currentScreen == .latentSpace { latentLabSelectedArea = nil }
                if currentScreen == .conditioningAndGuidance { conditioningLabSelectedArea = nil }
                currentScreen = previous
            }
        }
    }

    // MARK: - Bottom sheet topic sync

    private func syncSelectedComponentToCurrentStep() {
        let step = currentOverviewStep
        let next: ModelComponent
        if let forward = step.highlightForward {
            next = ModelComponent(UnifiedArchitectureComponent.from(forward))
        } else if let reverse = step.highlightReverse {
            next = ModelComponent(UnifiedArchitectureComponent.from(reverse))
        } else {
            next = .whatIsDiffusion
        }
        if selectedComponent != next {
            selectedComponent = next
        }
    }
}
