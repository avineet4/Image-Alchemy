import SwiftUI

struct ConditioningBox: View {
    let promptText: String
    let isActive: Bool
    
    @State private var glowAnimation = false
    
    private let boxColor: Color = .orange
    
    var body: some View {
        VStack(spacing: 6) {
            // Text label
            HStack(spacing: 4) {
                Image(systemName: "text.quote")
                    .font(.caption2)
                Text("Text")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(boxColor)
            
            // Prompt text
            Text("\"\(promptText)\"")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(boxColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(boxColor, lineWidth: isActive ? 3 : 1.5)
                )
        )
        .shadow(
            color: isActive ? boxColor.opacity(0.6) : .clear,
            radius: glowAnimation ? 12 : 6
        )
        .scaleEffect(isActive ? (glowAnimation ? 1.05 : 1.02) : 1.0)
        .animation(.smooth(duration: 0.9).repeatForever(autoreverses: true), value: glowAnimation)
        .onChange(of: isActive) { _, newValue in
            glowAnimation = newValue
        }
        .onAppear {
            if isActive {
                glowAnimation = true
            }
        }
    }
}
