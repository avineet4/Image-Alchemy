import SwiftUI

// Point in 3D latent space representing a learned representation (e.g. from a VAE encoder).
struct LatentPoint: Identifiable {
    let id: UUID
    let x: Double
    let y: Double
    let z: Double
    let category: String

    init(id: UUID = UUID(), x: Double, y: Double, z: Double, category: String) {
        self.id = id
        self.x = x
        self.y = y
        self.z = z
        self.category = category
    }
}

// Category metadata for legend and chart styling in latent space visualizations.
struct LatentCategory: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let description: String

    static let all: [LatentCategory] = [
        LatentCategory(id: "Portrait", name: "Portrait", icon: "person.fill", color: Color(red: 0.85, green: 0.55, blue: 0.35), description: "Faces, people"),
        LatentCategory(id: "Nature", name: "Nature", icon: "leaf.fill", color: Color(red: 0.2, green: 0.6, blue: 0.9), description: "Landscapes, plants"),
        LatentCategory(id: "Urban", name: "Urban", icon: "building.2.fill", color: Color(red: 0.2, green: 0.75, blue: 0.5), description: "Buildings, streets"),
        LatentCategory(id: "Abstract", name: "Abstract", icon: "paintbrush.fill", color: Color(red: 0.6, green: 0.4, blue: 0.85), description: "Patterns, textures")
    ]
}
