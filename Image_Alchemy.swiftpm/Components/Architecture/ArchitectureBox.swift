import SwiftUI

protocol ArchitectureBoxSpec {
    var label: String { get }
    var subtitle: String { get }
    var color: Color { get }
    var imageName: String? { get }
    var isTrapezoid: Bool { get }
    var mirrorsTrapezoid: Bool { get }
    var width: CGFloat { get }
    var height: CGFloat { get }
    var imageHeight: CGFloat { get }
    var fontSize: CGFloat { get }
}

struct ArchitectureBoxView<Component: ArchitectureBoxSpec>: View {
    let component: Component
    let isActive: Bool
    var onTap: (() -> Void)? = nil
    var widthOverride: CGFloat?

    @State private var glowAnimation = false

    var body: some View {
        let content = VStack(spacing: 4) {
            if let imageName = component.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: boxWidth - 12, height: component.imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RichText(text: component.label)
                    .font(.system(size: component.fontSize, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                Text(component.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: boxWidth, height: component.height)
        .background {
            if component.isTrapezoid {
                TrapezoidBoxShape(mirrored: component.mirrorsTrapezoid)
                    .fill(component.color.opacity(0.2))
                    .overlay {
                        TrapezoidBoxShape(mirrored: component.mirrorsTrapezoid)
                            .stroke(component.color, lineWidth: isActive ? 3 : 1.5)
                    }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(component.color.opacity(0.2))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(component.color, lineWidth: isActive ? 3 : 1.5)
                    }
            }
        }
        .shadow(color: isActive ? component.color.opacity(0.6) : .clear,
                radius: glowAnimation ? 12 : 6)
        .scaleEffect(isActive ? (glowAnimation ? 1.05 : 1.02) : 1)
        .animation(.smooth(duration: 0.9).repeatForever(autoreverses: true), value: glowAnimation)
        .onChange(of: isActive) { _, newValue in glowAnimation = newValue }
        .onAppear { glowAnimation = isActive }

        if let onTap {
            Button(action: onTap) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    private var boxWidth: CGFloat { widthOverride ?? component.width }
}

typealias ArchitectureBox = ArchitectureBoxView<ArchitectureComponent>

extension ArchitectureComponent: ArchitectureBoxSpec {
    var imageName: String? { self == .originalImage ? "OriginalImage" : nil }
    var isTrapezoid: Bool { self == .encoder }
    var mirrorsTrapezoid: Bool { false }
    var width: CGFloat { self == .diffusionProcess ? 110 : self == .encoder ? 105 : 60 }
    var height: CGFloat { isTrapezoid ? 100 : 60 }
    var imageHeight: CGFloat { 44 }
    var fontSize: CGFloat { 20 }
}

typealias ReverseArchitectureBox = ArchitectureBoxView<ReverseArchitectureComponent>

extension ReverseArchitectureComponent: ArchitectureBoxSpec {
    var imageName: String? { self == .generatedImage ? "CreatedImage" : nil }
    var isTrapezoid: Bool { self == .decoder || self == .conditioning }
    var mirrorsTrapezoid: Bool { self == .conditioning }
    var width: CGFloat {
        switch self {
        case .unetDenoiser: 70
        case .decoder, .conditioning: 105
        case .generatedImage: 60
        default: 55
        }
    }
    var height: CGFloat { isTrapezoid ? 95 : 55 }
    var imageHeight: CGFloat { 40 }
    var fontSize: CGFloat { 18 }
}
