import SwiftUI

// ViewModel for the Random Variables topic
@MainActor
@Observable
final class RandomVariablesViewModel {

    // MARK: - Properties

    private let initialSampleCount = 64
    private let gridSize = 24
    private let maxSamples = 80

    var samples: [Double]
    var noiseGrid: [[Double]]
    var lastDrawnSample: Double?
    var isDrawingSample = false
    var selectedSampleIndex: Int?

    init() {
        self.samples = GaussianSampling.makeGaussianSamples(count: 64)
        self.noiseGrid = GaussianSampling.makeGrid(size: 24)
    }

    // MARK: - Actions

    func resampleAll() {
        withAnimation(.bouncy) {
            samples = GaussianSampling.makeGaussianSamples(count: initialSampleCount)
            noiseGrid = GaussianSampling.makeGrid(size: gridSize)
            lastDrawnSample = nil
            selectedSampleIndex = nil
        }
    }

    func drawSingleSample() {
        guard !isDrawingSample else { return }
        isDrawingSample = true
        let newSample = GaussianSampling.gaussianSample()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            samples.insert(newSample, at: 0)
            if samples.count > maxSamples { samples.removeLast() }
            lastDrawnSample = newSample
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isDrawingSample = false
        }
    }

    func selectSample(_ index: Int?) {
        selectedSampleIndex = index
    }
}
