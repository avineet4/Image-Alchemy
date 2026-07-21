import SwiftUI

struct HorizontalDataStream: View {
    let color: Color
    let isActive: Bool
    var height: CGFloat = 4
    var width: CGFloat = 60
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(isActive ? 0.8 : 0.3),
                        color.opacity(isActive ? 0.6 : 0.2)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .overlay(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        color.opacity(0.6),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: width * 0.4, height: height)
                            .offset(x: animationPhase * width - width * 0.2)
                    }
                }
            )
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        animationPhase = 1.0
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        animationPhase = 1.0
                    }
                } else {
                    animationPhase = 0
                }
            }
    }
}
