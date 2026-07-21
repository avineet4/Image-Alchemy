import SwiftUI

struct FlipCardView: View {
    let term: String
    let definition: String
    @Binding var isFlipped: Bool
    let color: Color
    
    var body: some View {
        ZStack {
            CardFace(text: term, label: "Term", color: color)
                .rotation3DEffect(.degrees(isFlipped ? -180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
            
            CardFace(text: definition, label: "Definition", color: color)
                .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
    }
}

struct CardFace: View {
    let text: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .textCase(.uppercase)
            
            Text(text)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .frame(maxWidth: .infinity)
        }
        .padding(32)
        .frame(maxWidth: 500)
        .frame(minHeight: 250)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
