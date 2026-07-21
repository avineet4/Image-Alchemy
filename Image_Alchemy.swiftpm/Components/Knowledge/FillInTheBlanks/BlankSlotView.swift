import SwiftUI

// MARK: - Drop zone

struct BlankSlotView: View {
    let filledWord: String?
    let correctWord: String
    let hasChecked: Bool
    let onDrop: (String) -> Void
    let onRemove: () -> Void
    
    @State private var isTargeted = false
    
    private var slotColor: Color {
        if hasChecked, let filled = filledWord {
            return filled == correctWord ? .green : .red
        }
        return isTargeted ? .orange.opacity(0.5) : .orange.opacity(0.2)
    }
    
    var body: some View {
        Group {
            if let word = filledWord {
                HStack(spacing: 6) {
                    Text(word)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(hasChecked ? (word == correctWord ? .green : .red) : .primary)
                    
                    if !hasChecked {
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(slotColor.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(slotColor, lineWidth: 1.5)
                        )
                )
            } else {
                Text("_____")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 80, minHeight: 40)
                    .background(
                        Capsule()
                            .fill(slotColor)
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                            )
                    )
            }
        }
        .dropDestination(for: FillInBlankWord.self) { items, _ in
            guard let item = items.first else { return false }
            onDrop(item.word)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
        .scaleEffect(isTargeted ? 1.05 : 1)
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
}
