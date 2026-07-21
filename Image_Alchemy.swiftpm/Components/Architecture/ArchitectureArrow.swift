import SwiftUI

struct ArchitectureArrow: View {
    let isAnimating: Bool
    var width: CGFloat = 30
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            ArrowShape()
                .stroke(
                    Color.primary.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
            
            if isAnimating {
                ArrowShape()
                    .trim(from: phase, to: min(phase + 0.4, 1.0))
                    .stroke(
                        Color.primary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
            }
        }
        .frame(width: width, height: 20)
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        phase = 0
        withAnimation(.smooth(duration: 1.2).repeatForever(autoreverses: false)) {
            phase = 1.0
        }
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let midY = rect.midY
        let arrowHeadSize: CGFloat = 6
        
        path.move(to: CGPoint(x: 0, y: midY))
        path.addLine(to: CGPoint(x: rect.width - arrowHeadSize, y: midY))
        
        path.move(to: CGPoint(x: rect.width - arrowHeadSize, y: midY - arrowHeadSize))
        path.addLine(to: CGPoint(x: rect.width, y: midY))
        path.addLine(to: CGPoint(x: rect.width - arrowHeadSize, y: midY + arrowHeadSize))
        
        return path
    }
}
