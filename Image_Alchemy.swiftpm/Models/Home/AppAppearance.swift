import SwiftUI

// App appearance mode options
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var previewBackgroundColor: Color {
        switch self {
        case .system: return Color(.systemGray5)
        case .light: return Color.white
        case .dark: return Color(.darkGray)
        }
    }

    var previewForegroundColor: Color {
        switch self {
        case .system: return .primary
        case .light: return .black
        case .dark: return .white
        }
    }
}
