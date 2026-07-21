import SwiftUI

struct StepNavigationButtons: View {
    let canGoPrevious: Bool
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Previous button
            Button(action: onPrevious) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                    Text("Previous")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .padding(.vertical, 10)
                .foregroundStyle(canGoPrevious ? Color.accentColor : Color.secondary)
                .opacity(canGoPrevious ? 1.0 : 0.4)
            }
            .disabled(!canGoPrevious)
            
            // Next button
            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text("Next")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .padding(.vertical, 10)
                .foregroundStyle(canGoNext ? Color.accentColor : Color.secondary)
                .opacity(canGoNext ? 1.0 : 0.4)
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal)
    }
}
