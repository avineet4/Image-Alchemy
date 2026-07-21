import SwiftUI

struct KnowledgeProgressIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    let labelFormat: (Int, Int) -> String
    let activeColor: Color
    let dotColor: (Int) -> Color
    
    init(
        currentIndex: Int,
        totalCount: Int,
        labelFormat: @escaping (Int, Int) -> String = { "\($0) of \($1)" },
        activeColor: Color = .blue,
        dotColor: @escaping (Int) -> Color = { _ in .secondary.opacity(0.3) }
    ) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.labelFormat = labelFormat
        self.activeColor = activeColor
        self.dotColor = dotColor
    }
    
    var body: some View {
        HStack {
            Text(labelFormat(currentIndex + 1, totalCount))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<totalCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? activeColor : dotColor(index))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}
