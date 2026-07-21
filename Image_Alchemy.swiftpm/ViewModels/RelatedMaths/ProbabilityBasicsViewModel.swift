import SwiftUI

// ViewModel for the Probability Basics topic
@MainActor
@Observable
final class ProbabilityBasicsViewModel {

    // MARK: - Properties

    static let expectationOutcomes: [(value: Double, weight: Double)] = [
        (1.0, 0.2),
        (2.0, 0.5),
        (3.0, 0.3)
    ]

    var eventProbability: Double = 0.35
    var coinFlips: [Bool] = []
    var isFlipping = false
    var expectationSamples: [Double] = []

    var headsCount: Int { coinFlips.filter { $0 }.count }
    var tailsCount: Int { coinFlips.filter { !$0 }.count }
    var empiricalProbability: Double {
        guard !coinFlips.isEmpty else { return 0.5 }
        return Double(headsCount) / Double(coinFlips.count)
    }
    var theoreticalExpectation: Double {
        Self.expectationOutcomes.reduce(0) { $0 + $1.value * $1.weight }
    }
    var sampleExpectation: Double {
        guard !expectationSamples.isEmpty else { return 0 }
        return expectationSamples.reduce(0, +) / Double(expectationSamples.count)
    }

    // MARK: - Actions

    func setEventProbability(_ value: Double) {
        withAnimation(.smooth(duration: 0.2)) {
            eventProbability = value
        }
    }

    func flipCoin() {
        guard !isFlipping else { return }
        isFlipping = true
        let result = Bool.random()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            coinFlips.append(result)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.isFlipping = false
        }
    }

    func resetCoinFlips() {
        withAnimation(.smooth(duration: 0.3)) {
            coinFlips.removeAll()
        }
    }

    func addExpectationSample() {
        let r = Double.random(in: 0..<1)
        var cum = 0.0
        var sampled = 0.0
        for (value, weight) in Self.expectationOutcomes {
            cum += weight
            if r < cum {
                sampled = value
                break
            }
        }
        withAnimation(.smooth(duration: 0.2)) {
            expectationSamples.append(sampled)
        }
    }

    func resetExpectationSamples() {
        withAnimation(.smooth(duration: 0.3)) {
            expectationSamples.removeAll()
        }
    }
}
