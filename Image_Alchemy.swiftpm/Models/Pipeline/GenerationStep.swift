import Foundation

// A single step in the AI generation process, displayed to the user as progress feedback.
struct GenerationStep: Identifiable {
    let id: UUID
    let message: String
    let icon: String
    
    init(id: UUID = UUID(), message: String, icon: String) {
        self.id = id
        self.message = message
        self.icon = icon
    }
}
