import SwiftUI

// Shared 8×8 latent grid data and chart points for reuse (e.g. Latent Space lab and Forward Diffusion lab).
enum LatentGridData {
    static let rows = 8
    static let columns = 8

    static let sampledGrid: [[Double]] = [
        [0.12, 0.13, 0.14, 0.16, 0.22, 0.30, 0.35, 0.40],
        [0.15, 0.18, 0.20, 0.25, 0.32, 0.45, 0.55, 0.62],
        [0.25, 0.30, 0.38, 0.45, 0.60, 0.75, 0.82, 0.86],
        [0.30, 0.36, 0.48, 0.58, 0.72, 0.88, 0.94, 0.97],
        [0.28, 0.34, 0.46, 0.55, 0.70, 0.86, 0.93, 0.96],
        [0.24, 0.30, 0.38, 0.46, 0.60, 0.78, 0.85, 0.90],
        [0.18, 0.22, 0.26, 0.32, 0.42, 0.55, 0.63, 0.70],
        [0.14, 0.18, 0.22, 0.26, 0.35, 0.48, 0.56, 0.62],
    ]

    struct GridPoint3D: Identifiable {
        let id: Int
        let x: Double
        let y: Double
        let z: Double
    }

    static var chartData: [GridPoint3D] {
        var points: [GridPoint3D] = []
        for row in 0..<rows {
            for col in 0..<columns {
                let index = row * columns + col
                points.append(GridPoint3D(
                    id: index,
                    x: Double(col),
                    y: Double(rows - 1 - row),
                    z: sampledGrid[row][col]
                ))
            }
        }
        return points
    }

    static func colorForMagnitude(_ magnitude: Double) -> Color {
        if magnitude < 0.25 {
            return Color(hue: 0.58, saturation: 0.5, brightness: 0.4 + 0.5 * magnitude)
        } else if magnitude < 0.45 {
            return Color(hue: 0.52, saturation: 0.55, brightness: 0.45 + 0.4 * magnitude)
        } else if magnitude < 0.65 {
            return Color(hue: 0.78, saturation: 0.5, brightness: 0.5 + 0.35 * magnitude)
        } else {
            return Color(hue: 0.08, saturation: 0.6, brightness: 0.55 + 0.35 * magnitude)
        }
    }
}
