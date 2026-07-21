import SwiftUI

// MARK: - Dot Product Equation Parts

enum DotProductEquationPart: String, CaseIterable {
    case notation
    case summation
    case components  
    
    var title: String {
        switch self {
        case .notation: return "Notation"
        case .summation: return "Summation"
        case .components: return "Component-wise Multiplication"
        }
    }
    
    var explanation: String {
        switch self {
        case .notation:
            return "The angle brackets ⟨ ⟩ denote the dot product of vectors x and y. This is a common mathematical notation for inner products."
        case .summation:
            return "The sigma (∑) means we sum over all components i from 1 to n, where n is the dimension of the vectors."
        case .components:
            return "For each position i, multiply the i-th component of x with the i-th component of y, then sum all products. This gives us a single scalar value."
        }
    }
    
    var example: String? {
        switch self {
        case .notation:
            return "⟨x, y⟩ = ⟨y, x⟩ (commutative)"
        case .summation:
            return "If n=3: ∑ᵢ means i goes from 1 to 3"
        case .components:
            return "If x = [1, 2, 3] and y = [4, 5, 6]:\n1×4 + 2×5 + 3×6 = 32"
        }
    }
}

struct VectorsAndDotProductView: View {
    @State private var viewModel = VectorsAndDotProductViewModel()
    @State private var selectedPart: DotProductEquationPart?

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dot product of two vectors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 6) {
                        DotProductPartButton(
                            text: "⟨x, y⟩",
                            part: .notation,
                            selectedPart: $selectedPart
                        )
                        
                        ScriptText(raw: "=", baseSize: 28)
                        
                        DotProductPartButton(
                            text: "∑_{i}",
                            part: .summation,
                            selectedPart: $selectedPart
                        )
                        
                        DotProductPartButton(
                            text: "x_{i} y_{i}",
                            part: .components,
                            selectedPart: $selectedPart
                        )
                    }
                    .padding(.vertical, 12)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.7))
                        Text("Tap any part of the equation to learn more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .animation(.smooth(duration: 0.2), value: selectedPart)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                
                if let selectedPart = selectedPart {
                    DotProductExplanationBox(part: selectedPart)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            }
            .animation(.smooth(duration: 0.35), value: selectedPart?.rawValue)

            ImageToVectorView()

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 16) {
                    DotProductVisualizationView(angle: $viewModel.angle)
                        .frame(minWidth: 600)
                        .animation(.bouncy(duration: 0.35), value: viewModel.angle)
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "hand.draw")
                            .font(.caption)
                            .foregroundStyle(.indigo.opacity(0.7))
                        Text("Drag the angle arc in the diagram above to change θ and see how the dot product (cos(θ)) responds.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 250, alignment: .leading)
                    }
                }
            }

            Divider()

            NumericDotProductView(
                vectorX: $viewModel.vectorX,
                vectorY: $viewModel.vectorY,
                dotProduct: viewModel.dotProduct
            )

            RichText(text: "Diffusion models work on **vectors**, not raw images. We flatten an image (or its features) into a long list of numbers, then apply linear algebra operations like dot products.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Intuition")
                    .font(.headline)

                bullet("A **vector** is just an ordered list of numbers (e.g. all the pixels in an image).")
                bullet("The **dot product** measures how aligned two vectors are (similar direction → large value).")
                bullet("Neural network layers are mostly dot products plus simple nonlinearities.")
            }
        }
        .padding()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            RichText(text: text)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Equation Part Button

private struct DotProductPartButton: View {
    let text: String
    let part: DotProductEquationPart
    @Binding var selectedPart: DotProductEquationPart?
    var delay: Double = 0
    
    var isSelected: Bool {
        selectedPart == part
    }
    
    @State private var appeared = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedPart == part {
                    selectedPart = nil
                } else {
                    selectedPart = part
                }
            }
        } label: {
            ScriptText(
                raw: text,
                baseSize: 24,
                weight: isSelected ? .semibold : .regular
            )
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.secondary.opacity(0.2) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.secondary.opacity(0.4) : .clear, lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 6)
        .onAppear {
            withAnimation(.smooth(duration: 0.4).delay(delay)) {
                appeared = true
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Explanation Box

private struct DotProductExplanationBox: View {
    let part: DotProductEquationPart
    
    var body: some View {
        ZStackLayout(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(.secondary)
                        .frame(width: 8, height: 8)
                    
                    Text(part.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                HStack(alignment: .top, spacing: 16) {
                    Text(part.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let example = part.example {
                        Divider()
                            .frame(height: 60)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Example:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Text(example)
                                .font(.caption)
                                .fontDesign(.monospaced)
                                .foregroundStyle(.primary)
                        }
                        .frame(minWidth: 120, alignment: .leading)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 400, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

// MARK: - Supporting Views

private struct ImageToVectorView: View {
    private let gridSize = 4
    private let pixelValues: [[Double]] = [
        [0.2, 0.8, 0.5, 0.3],
        [0.6, 0.9, 0.4, 0.7],
        [0.1, 0.5, 0.6, 0.2],
        [0.4, 0.3, 0.8, 0.9]
    ]

    @Namespace private var transferNamespace
    @State private var transferredCount: Int = 0
    @State private var isAnimating: Bool = true

    private var flattened: [Double] {
        pixelValues.flatMap { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Image → Vector: flatten pixels into a list")
                .font(.subheadline.weight(.semibold))
            
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .center, spacing: 4) {
                        Text("4×4 image")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(24), spacing: 2), count: gridSize), spacing: 2) {
                            ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                                let row = index / gridSize
                                let col = index % gridSize
                                let isTransferred = index < transferredCount
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(
                                        LinearGradient(
                                            colors: [.indigo.opacity(0.4), .indigo],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .opacity(isTransferred ? 0 : pixelValues[row][col])
                                    .frame(width: 24, height: 24)
                                    .matchedGeometryEffect(
                                        id: index,
                                        in: transferNamespace,
                                        isSource: !isTransferred
                                    )
                            }
                        }
                    }
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Vector (16 numbers)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal) {
                            HStack(spacing: 4) {
                                ForEach(flattened.indices, id: \.self) { i in
                                    let isActive = i < transferredCount
                                    let intensity = flattened[i]
                                    let activeOpacity = 0.3 + 0.7 * intensity
                                    let inactiveOpacity = 0.15 + 0.45 * intensity
                                    Text(flattened[i], format: .number.precision(.fractionLength(1)))
                                        .font(.system(size: 11, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            .indigo.opacity(isActive ? activeOpacity : inactiveOpacity),
                                                            .indigo.opacity(isActive ? activeOpacity + 0.1 : inactiveOpacity + 0.1)
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                        )
                                        .foregroundStyle(isActive ? .white : .primary.opacity(0.75))
                                        .matchedGeometryEffect(
                                            id: i,
                                            in: transferNamespace,
                                            isSource: isActive
                                        )
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    .offset(x: -180)
                }
                .frame(maxWidth: .infinity)
                .offset(x: -150)
                .padding(.vertical, 12)
                .padding(.leading, 12)
                .padding(.bottom, 12)
                .padding(.trailing, -230)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemBackground))
                )

                Button {
                    withAnimation(.snappy(duration: 0.15)) {
                        isAnimating.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isAnimating ? "pause.fill" : "play.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .glassEffect(.regular.tint(.indigo).interactive(), in: .circle)
                .padding([.top, .trailing], 10)
            }
            .task(id: isAnimating) {
                if isAnimating {
                    await runTransferAnimation()
                }
            }
        }
    }

    private func runTransferAnimation() async {
        let total = flattened.count
        guard total > 0 else { return }

        while !Task.isCancelled {
            await MainActor.run {
                transferredCount = 0
            }

            try? await Task.sleep(for: .seconds(0.8))

            for step in 1...total {
                await MainActor.run {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        transferredCount = step
                    }
                }

                try? await Task.sleep(for: .seconds(0.4))
            }

            try? await Task.sleep(for: .seconds(1.2))
        }
    }
}

private struct NumericDotProductView: View {
    @Binding var vectorX: [Double]
    @Binding var vectorY: [Double]
    let dotProduct: Double
    @State private var scale: CGFloat = 1.0
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .center, spacing: 16) {
                Text("⟨x, y⟩ = x₁y₁ + x₂y₂ + x₃y₃")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : -10)
                
                HStack(alignment: .center, spacing: 16) {
                    VectorEditor(label: "x", values: $vectorX)
                    Text("·")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                    VectorEditor(label: "y", values: $vectorY)
                    Text("=")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(dotProduct, format: .number.precision(.fractionLength(2)))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.indigo)
                        .monospacedDigit()
                        .frame(minWidth: 50, alignment: .leading)
                        .scaleEffect(scale)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemBackground))
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
            }

            if vectorX.count == vectorY.count && !vectorX.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        ForEach(vectorX.indices, id: \.self) { index in
                            MultiplicationTermView(
                                x: vectorX[index],
                                y: vectorY[index],
                                index: index,
                                isLast: index == vectorX.count - 1,
                                hasAppeared: hasAppeared,
                                delay: Double(index) * 0.1
                            )
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 6) {
                        Text("=")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(x: hasAppeared ? 0 : -5)
                        Text(dotProduct, format: .number.precision(.fractionLength(2)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.indigo)
                            .monospacedDigit()
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(x: hasAppeared ? 0 : -5)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Text("Tap a number to edit. Dot product updates live.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .opacity(hasAppeared ? 1 : 0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dotProduct)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vectorX)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vectorY)
        .onChange(of: dotProduct) { oldValue, newValue in
            if oldValue != newValue {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    scale = 1.25
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }

    private var breakdownString: String {
        let terms = zip(vectorX, vectorY).map { (a, b) in
            "\(a.formatted(.number.precision(.fractionLength(2))))×\(b.formatted(.number.precision(.fractionLength(2))))"
        }
        return terms.joined(separator: " + ") + " = \(dotProduct.formatted(.number.precision(.fractionLength(2))))"
    }
}

private struct MultiplicationTermView: View {
    let x: Double
    let y: Double
    let index: Int
    let isLast: Bool
    let hasAppeared: Bool
    let delay: Double
    @State private var scale: CGFloat = 1.0
    @State private var multiplyScale: CGFloat = 1.0
    @State private var multiplyOpacity: Double = 0.8
    @State private var previousX: Double = 0
    @State private var previousY: Double = 0
    
    private var product: Double {
        x * y
    }
    
    var body: some View {
        HStack(spacing: 3) {
            Text(x, format: .number.precision(.fractionLength(2)))
                .monospacedDigit()
                .scaleEffect(scale)
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : -10)
            
            Text("×")
                .foregroundStyle(.indigo.opacity(multiplyOpacity))
                .scaleEffect(multiplyScale)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 5)
            
            Text(y, format: .number.precision(.fractionLength(2)))
                .monospacedDigit()
                .scaleEffect(scale)
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : 10)
            
            if !isLast {
                Text("+")
                    .foregroundStyle(.secondary.opacity(0.6))
                    .padding(.leading, 4)
                    .opacity(hasAppeared ? 1 : 0)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay), value: hasAppeared)
        .onChange(of: x) { oldValue, newValue in
            if oldValue != newValue {
                animateMultiplication()
            }
        }
        .onChange(of: y) { oldValue, newValue in
            if oldValue != newValue {
                animateMultiplication()
            }
        }
        .onAppear {
            previousX = x
            previousY = y
        }
    }
    
    private func animateMultiplication() {
        // Animate the entire term
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.3
        }
        
        // Animate the multiplication symbol with a pulse effect
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            multiplyScale = 1.5
            multiplyOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
                multiplyScale = 1.0
                multiplyOpacity = 0.8
            }
        }
    }
}


private struct VectorEditor: View {
    let label: String
    @Binding var values: [Double]
    @State private var hasAppeared = false

    private func binding(for index: Int) -> Binding<Double> {
        Binding(
            get: { values.indices.contains(index) ? values[index] : 0 },
            set: { newValue in
                guard values.indices.contains(index) else { return }
                var copy = values
                copy[index] = newValue
                values = copy
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Vector \(label)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : -10)
            
            HStack(spacing: 6) {
                Text("[")
                    .opacity(hasAppeared ? 1 : 0)
                ForEach(values.indices, id: \.self) { i in
                    VectorTextField(
                        value: binding(for: i),
                        index: i,
                        isFirst: i == 0,
                        hasAppeared: hasAppeared,
                        delay: Double(i) * 0.05
                    )
                }
                Text("]")
                    .opacity(hasAppeared ? 1 : 0)
            }
            .font(.system(.body, design: .monospaced))
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }
}

private struct VectorTextField: View {
    @Binding var value: Double
    let index: Int
    let isFirst: Bool
    let hasAppeared: Bool
    let delay: Double
    @State private var scale: CGFloat = 1.0
    @State private var previousValue: Double = 0
    
    var body: some View {
        HStack(spacing: 2) {
            if !isFirst {
                Text(",")
                    .opacity(hasAppeared ? 1 : 0)
            }
            TextField("", value: $value, format: .number.precision(.fractionLength(2)))
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.center)
                .frame(width: 80)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .scaleEffect(scale)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 5)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(delay), value: hasAppeared)
        .onChange(of: value) { oldValue, newValue in
            if oldValue != newValue {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    scale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
            }
        }
        .onAppear {
            previousValue = value
        }
    }
}

private struct DotProductVisualizationView: View {
    @Binding var angle: Double

    var body: some View {
        let cosValue = cos(angle * .pi / 180)

        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                    Text("Aligned (0°) → dot product max")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("Perpendicular (90°) → 0")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("Opposite (180°) → min")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                
                    Spacer()

                    HStack(spacing: 4) {
                        Text("Angle \(Int(angle))°")
                        Text("•")
                        Text("cos(θ) ≈ \(cosValue, format: .number.precision(.fractionLength(2)))")
                            .foregroundStyle(.indigo)
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                }
            
            ZStack {
                Group {
                    Group {
                        Path { path in
                            path.move(to: CGPoint(x: 10, y: 60))
                            path.addLine(to: CGPoint(x: 90, y: 60))
                            path.move(to: CGPoint(x: 50, y: 100))
                            path.addLine(to: CGPoint(x: 50, y: 20))
                        }
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                        .frame(width: 100, height: 110)
                        
                        Arrow()
                            .stroke(
                                LinearGradient(
                                    colors: [.indigo, .indigo.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-25))
                            .offset(x: -5, y: 10)
                        
                        Arrow()
                            .stroke(
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-25 + angle))
                            .offset(x: 10, y: 10)
                    }
                    .scaleEffect(1.25)              
                    
                    ArcSelector(
                        value: $angle,
                        range: 0 ... 180
                    )
                }
            }
            .offset(y: 23)
            .scaleEffect(1.08)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

private struct Arrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.minX + rect.width * 0.2,
                            y: rect.maxY - rect.height * 0.2)
        let end = CGPoint(x: rect.maxX - rect.width * 0.1,
                          y: rect.minY + rect.height * 0.2)

        path.move(to: start)
        path.addLine(to: end)

        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 8
        let arrowAngle: CGFloat = .pi / 6

        let point1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let point2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        path.move(to: end)
        path.addLine(to: point1)
        path.move(to: end)
        path.addLine(to: point2)

        return path
    }
}
