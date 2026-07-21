import SwiftUI

// Represents a navigation destination on the home screen
struct NavigationItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: Destination
    
    enum Destination: String, CaseIterable {
        case fullPipeline
        case relatedMaths
        case knowledge
    }
}
