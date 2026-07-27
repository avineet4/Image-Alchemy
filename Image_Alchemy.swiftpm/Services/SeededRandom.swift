struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed)
    }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64.max >> 11)
    }
}
