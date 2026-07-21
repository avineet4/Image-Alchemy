import SwiftUI

struct TrapezoidBoxShape: Shape {
    var mirrored: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Points based on the reference image style
        // Base points (non-mirrored, pointing right).
        var topLeft = CGPoint(x: rect.minX + rect.width * 0.25,
                              y: rect.minY + rect.height * 0.15)
        var topRight = CGPoint(x: rect.minX + rect.width * 0.85,
                               y: rect.minY + rect.height * 0.35)
        var bottomRight = CGPoint(x: rect.minX + rect.width * 0.85,
                                  y: rect.minY + rect.height * 0.75)
        var bottomLeft = CGPoint(x: rect.minX + rect.width * 0.25,
                                 y: rect.minY + rect.height * 0.95)

        if mirrored {
            // Mirror horizontally across the vertical center of the rect.
            let centerX = rect.midX
            func mirror(_ point: CGPoint) -> CGPoint {
                let dx = point.x - centerX
                return CGPoint(x: centerX - dx, y: point.y)
            }
            topLeft = mirror(topLeft)
            topRight = mirror(topRight)
            bottomRight = mirror(bottomRight)
            bottomLeft = mirror(bottomLeft)
        }

        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()
        return path
    }
}

