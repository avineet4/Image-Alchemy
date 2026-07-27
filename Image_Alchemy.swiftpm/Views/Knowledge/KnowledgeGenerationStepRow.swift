import SwiftUI

struct KnowledgeGenerationStepRow: View {
    let step: GenerationStep
    let index: Int
    let stepCount: Int

    var body: some View {
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
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.96)),
            removal: .opacity
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(Double(index) * 0.06), value: stepCount)
    }
}
