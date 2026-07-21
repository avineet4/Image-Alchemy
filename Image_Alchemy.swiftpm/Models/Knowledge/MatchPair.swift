import Foundation

// A pair of items to be matched (left term ↔ right definition)
struct MatchPair: Identifiable {
    let id: UUID
    let leftItem: String
    let rightItem: String
    
    init(id: UUID = UUID(), leftItem: String, rightItem: String) {
        self.id = id
        self.leftItem = leftItem
        self.rightItem = rightItem
    }
}

// MARK: - Static Sample Data

extension MatchPair {
    // Sample match pairs for diffusion model concepts
    static let samplePairs: [MatchPair] = [
        MatchPair(leftItem: "Forward Process", rightItem: "Adds Gaussian noise over T timesteps"),
        MatchPair(leftItem: "Reverse Process", rightItem: "Removes noise to generate a clean image"),
        MatchPair(leftItem: "U-Net", rightItem: "Predicts noise at each denoising step"),
        MatchPair(leftItem: "Noise Schedule (βₜ)", rightItem: "Controls how much noise at each step t"),
        MatchPair(leftItem: "Latent Space", rightItem: "Compressed representation from VAE"),
    ]
}
