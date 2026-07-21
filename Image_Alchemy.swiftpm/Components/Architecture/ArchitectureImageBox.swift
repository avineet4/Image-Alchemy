import SwiftUI

struct ArchitectureImageBox: View {
    let imageName: String
    let size: CGSize
    let color: Color
    let isActive: Bool
    let onTap: () -> Void
    
    @State private var glowAnimation = false
    
    var body: some View {
        Button(action: onTap) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .shadow(
            color: isActive ? color.opacity(0.6) : .clear,
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

