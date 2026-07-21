import SwiftUI

struct ArchitectureBox: View {
    let component: ArchitectureComponent
    let isActive: Bool
    var onTap: (() -> Void)? = nil
    
    @State private var glowAnimation = false
    
    private var boxColor: Color {
        component.color
    }
    
    var body: some View {
        let isTrapezoid = component == .encoder
        let boxHeight: CGFloat = isTrapezoid ? 100 : 60

        let content = VStack(spacing: 4) {
            if component == .originalImage {
                Image("OriginalImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: componentWidth - 12, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RichText(text: component.label)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                
                Text(component.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: componentWidth, height: boxHeight)
        .background(
            Group {
                if isTrapezoid {
                    TrapezoidBoxShape()
                        .fill(boxColor.opacity(0.2))
                        .overlay(
                            TrapezoidBoxShape()
                                .stroke(boxColor, lineWidth: isActive ? 3 : 1.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(boxColor.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(boxColor, lineWidth: isActive ? 3 : 1.5)
                        )
                }
            }
        )
        .shadow(
            color: isActive ? boxColor.opacity(0.6) : .clear,
            radius: glowAnimation ? 12 : 6
        )
        .scaleEffect(isActive ? (glowAnimation ? 1.05 : 1.02) : 1.0)
        .animation(.smooth(duration: 0.9).repeatForever(autoreverses: true), value: glowAnimation)
        .onChange(of: isActive) { _, newValue in
            glowAnimation = newValue
        }
        .onAppear {
            if isActive {
                glowAnimation = true
            }
        }
        
        if let onTap = onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
    
    private var componentWidth: CGFloat {
        switch component {
        case .diffusionProcess:
            return 110
        case .encoder:
            return 105
        default:
            return 60
        }
    }
}
