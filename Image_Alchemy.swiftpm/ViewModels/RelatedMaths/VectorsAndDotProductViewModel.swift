import SwiftUI

// ViewModel for the Vectors and Dot Product topic
@MainActor
@Observable
final class VectorsAndDotProductViewModel {

    // MARK: - Properties

    var angle: Double = 45
    var vectorX: [Double] = [1.0, 2.0, 0.5]
    var vectorY: [Double] = [0.5, 1.0, 2.0]

    var dotProduct: Double {
        zip(vectorX, vectorY).map(*).reduce(0, +)
    }

    // MARK: - Actions

    func setAngle(_ value: Double) {
        withAnimation(.bouncy(duration: 0.3)) {
            angle = value
        }
    }
}
