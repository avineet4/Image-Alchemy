import SwiftUI

// ViewModel for the Home screen
@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Properties

    let appTitle = "Image Alchemy"
    let appIcon = "wand.and.stars"

    var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance")
        }
    }

    var showAppearancePicker = false
    
    let navigationItems: [NavigationItem] = [
        NavigationItem(
            id: "fullPipeline",
            title: "Full Pipeline",
            subtitle: "Architecture overview",
            icon: "play.circle.fill",
            color: .purple,
            destination: .fullPipeline
        ),
        NavigationItem(
            id: "maths",
            title: "Related Maths",
            subtitle: "Explore the mathematics behind diffusion",
            icon: "function",
            color: .orange,
            destination: .relatedMaths
        ),
        NavigationItem(
            id: "knowledge",
            title: "Test Your Knowledge",
            subtitle: "Learn key concepts and terminology",
            icon: "book.fill",
            color: .indigo,
            destination: .knowledge
        )
    ]
    
    // MARK: - Initialization
    
    init() {
        if let savedAppearance = UserDefaults.standard.string(forKey: "appAppearance"),
           let appearance = AppAppearance(rawValue: savedAppearance) {
            self.appearance = appearance
        } else {
            self.appearance = .system
        }
    }
    
    // MARK: - Actions
    
    func cycleAppearance() {
        let allCases = AppAppearance.allCases
        if let currentIndex = allCases.firstIndex(of: appearance) {
            let nextIndex = (currentIndex + 1) % allCases.count
            withAnimation(.easeInOut(duration: 0.3)) {
                appearance = allCases[nextIndex]
            }
        }
    }

    func presentAppearancePicker() {
        showAppearancePicker = true
    }

    func selectAppearance(_ appearance: AppAppearance) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.appearance = appearance
        }
    }
}
