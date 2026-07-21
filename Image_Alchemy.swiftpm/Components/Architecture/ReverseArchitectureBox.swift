import SwiftUI

// A reusable box component for the reverse architecture diagram
// Displays a labeled box with optional glow effect when active
struct ReverseArchitectureBox: View {
    let component: ReverseArchitectureComponent
    let isActive: Bool
    // When set, the box is tappable and shows an explanation panel.
    var onTap: (() -> Void)? = nil
    // Optional override for the box width, used for special layouts.
    let widthOverride: CGFloat?
    
    @State private var glowAnimation = false
    
    private var boxColor: Color {
        component.color
    }

    init(
        component: ReverseArchitectureComponent,
        isActive: Bool,
        onTap: (() -> Void)? = nil,
        widthOverride: CGFloat? = nil
    ) {
        self.component = component
        self.isActive = isActive
        self.onTap = onTap
        self.widthOverride = widthOverride
    }
    
    var body: some View {
        let isDecoderTrapezoid = component == .decoder
        let isConditioningTrapezoid = component == .conditioning
        let isTrapezoid = isDecoderTrapezoid || isConditioningTrapezoid
        let boxHeight: CGFloat = isTrapezoid ? 95 : 55

        let content = VStack(spacing: 4) {
            if component == .generatedImage {
                Image("CreatedImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: componentWidth - 12, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RichText(text: component.label)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                
                Text(component.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: componentWidth, height: boxHeight)
        .background(
            Group {
                if isDecoderTrapezoid {
                    TrapezoidBoxShape()
                        .fill(boxColor.opacity(0.2))
                        .overlay(
                            TrapezoidBoxShape()
                                .stroke(boxColor, lineWidth: isActive ? 3 : 1.5)
                        )
                } else if isConditioningTrapezoid {
                    // Use a horizontally mirrored trapezoid for conditioning.
                    TrapezoidBoxShape(mirrored: true)
                        .fill(boxColor.opacity(0.2))
                        .overlay(
                            TrapezoidBoxShape(mirrored: true)
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
        if let widthOverride {
            return widthOverride
        }
        switch component {
        case .unetDenoiser:
            return 70
        case .decoder, .conditioning:
            return 105
        case .generatedImage:
            return 60
        default:
            return 55
        }
    }
}
