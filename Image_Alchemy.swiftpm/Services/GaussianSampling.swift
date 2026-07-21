import Foundation

// Utility for generating Gaussian (normal) noise samples using Box-Muller transform.
enum GaussianSampling {

    static func gaussianSample() -> Double {
        let u1 = Double.random(in: 0.001...1)
        let u2 = Double.random(in: 0...1)
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }

    static func makeGaussianSamples(count: Int) -> [Double] {
        (0..<count).map { _ in gaussianSample() }
    }

    // Generate a 2D grid of Gaussian samples
    static func makeGrid(size: Int) -> [[Double]] {
        (0..<size).map { _ in
            (0..<size).map { _ in gaussianSample() }
        }
    }
}
