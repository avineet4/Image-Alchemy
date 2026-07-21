import SwiftUI

struct ArchitectureContainer<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                // .fontWidth(.expanded)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .center, spacing: 16) {
                content
            }
            .padding(12)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
        }
    }
}
