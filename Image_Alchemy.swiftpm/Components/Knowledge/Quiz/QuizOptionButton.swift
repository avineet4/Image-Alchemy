import SwiftUI

// Multiple-choice option button for Quiz mode
struct QuizOptionButton: View {
    let option: String
    let optionLabel: String
    let isSelected: Bool
    let isCorrect: Bool
    let showFeedback: Bool
    let action: () -> Void
    
    private var feedbackColor: Color? {
        guard showFeedback else { return nil }
        if isCorrect { return .green }
        if isSelected && !isCorrect { return .red }
        return nil
    }
    
    private var feedbackIcon: String? {
        guard showFeedback else { return nil }
        if isCorrect { return "checkmark.circle.fill" }
        if isSelected && !isCorrect { return "xmark.circle.fill" }
        return nil
    }
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                Text(optionLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(feedbackColor ?? .blue)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill((feedbackColor ?? .blue).opacity(0.15)))
                
                Text(option)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let icon = feedbackIcon, let color = feedbackColor {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(feedbackColor ?? Color.clear, lineWidth: feedbackColor != nil ? 2 : 0)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(showFeedback)
    }
}
