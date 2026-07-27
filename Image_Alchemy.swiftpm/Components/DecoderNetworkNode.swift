import SwiftUI

struct DecoderNetworkNode: View {
    let isActive: Bool
    let color: Color
    let activeScale: CGFloat
    var size: CGFloat = 24

    var body: some View {
        Circle()
            .stroke(isActive ? color : color.opacity(0.5), lineWidth: 2)
            .background(Circle().fill(isActive ? color.opacity(0.18) : Color.white))
            .frame(width: size, height: size)
            .scaleEffect(isActive ? activeScale : 1)
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: 4, y: 2)
    }
}
