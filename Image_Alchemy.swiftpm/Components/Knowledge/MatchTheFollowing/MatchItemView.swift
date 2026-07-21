import SwiftUI

private let matchItemAccentColor = Color(red: 0.56, green: 0.49, blue: 0.43)

struct MatchItemView: View {
    let label: String
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    var isDropTarget: Bool = false
    let action: () -> Void
    
    private var borderColor: Color {
        if isCorrect { return .green }
        if isIncorrect { return .red }
        if isSelected { return matchItemAccentColor }
        return Color.clear
    }
    
    private var badgeColor: Color {
        if isCorrect { return .green }
        if isIncorrect { return .red }
        return matchItemAccentColor.opacity(0.9)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(badgeColor))
                
                Text(text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                if isIncorrect {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(MatchItemGlassModifier(isCorrect: isCorrect, isIncorrect: isIncorrect, isSelected: isSelected))
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: borderColor != .clear ? 2.5 : 0)
            )
            .overlay(
                Group {
                    if isDropTarget {
                        Capsule()
                            .strokeBorder(style: StrokeStyle(lineWidth: 2.5, dash: [8, 6]))
                            .foregroundStyle(matchItemAccentColor)
                    }
                }
            )
            .shadow(color: .black.opacity(isSelected || isCorrect || isIncorrect ? 0.08 : 0.06), radius: isSelected ? 10 : 6, y: 3)
        }
        .buttonStyle(MatchItemButtonStyle())
    }
}

private struct MatchItemGlassModifier: ViewModifier {
    let isCorrect: Bool
    let isIncorrect: Bool
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isCorrect {
            content.glassEffect(.regular.tint(Color.green.opacity(0.25)).interactive(), in: .capsule)
        } else if isIncorrect {
            content.glassEffect(.regular.tint(Color.red.opacity(0.25)).interactive(), in: .capsule)
        } else if isSelected {
            content.glassEffect(.regular.tint(matchItemAccentColor.opacity(0.2)).interactive(), in: .capsule)
        } else {
            content.glassEffect(.regular.interactive(), in: .capsule)
        }
    }
}

private struct MatchItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
