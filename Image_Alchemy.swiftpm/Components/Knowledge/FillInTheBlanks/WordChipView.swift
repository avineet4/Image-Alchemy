import SwiftUI

struct WordChipView: View {
    let word: String
    
    var body: some View {
        Text(word)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
    }
}
