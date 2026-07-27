import SwiftUI

@MainActor
protocol KnowledgeGenerationModel: AnyObject {
    var generationSteps: [GenerationStep] { get set }
}

extension KnowledgeGenerationModel {
    func addGenerationStep(_ step: GenerationStep, after delay: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            generationSteps.append(step)
        }
    }
}
