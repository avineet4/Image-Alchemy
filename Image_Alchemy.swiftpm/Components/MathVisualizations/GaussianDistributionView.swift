import SwiftUI

// Interactive visualization of Gaussian/Normal distribution
struct GaussianDistributionView: View {
    @Binding var mean: Double
    @Binding var stdDev: Double
    
    var body: some View {
        VStack(spacing: 20) {
            // Formula display
            Text("N(μ, σ²)")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(.primary)
            
            // Bell curve graph
            GaussianCurveCanvas(mean: mean, stdDev: stdDev)
                .frame(height: 180)
                .padding(.horizontal)
            
            // Sliders
            VStack(spacing: 16) {
                // Mean slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Mean (μ)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(mean, format: .number.precision(.fractionLength(2)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $mean, in: -3...3, step: 0.1)
                        .tint(.blue)
                }
                
                // Standard deviation slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Std Dev (σ)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(stdDev, format: .number.precision(.fractionLength(2)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $stdDev, in: 0.1...3, step: 0.1)
                        .tint(.orange)
                }
            }
            .padding(.horizontal)
            
            // Explanation
            Text("Diffusion models add Gaussian noise ε ~ N(0, 1) at each step")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct GaussianCurveCanvas: View {
    let mean: Double
    let stdDev: Double
    
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let padding: CGFloat = 20
            
            // Calculate the graph area
            let graphWidth = width - 2 * padding
            let graphHeight = height - 2 * padding
            
            // Draw axes
            let axisPath = Path { path in
                // X-axis
                path.move(to: CGPoint(x: padding, y: height - padding))
                path.addLine(to: CGPoint(x: width - padding, y: height - padding))
                
                // Y-axis
                path.move(to: CGPoint(x: padding, y: height - padding))
                path.addLine(to: CGPoint(x: padding, y: padding))
            }
            context.stroke(axisPath, with: .color(.secondary.opacity(0.5)), lineWidth: 1)
            
            // Draw the bell curve
            var curvePath = Path()
            let steps = 200
            let xRange: ClosedRange<Double> = -4...4
            
            // Calculate max PDF value for scaling
            let maxPDF = gaussianPDF(x: mean, mean: mean, stdDev: stdDev)
            
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let x = xRange.lowerBound + t * (xRange.upperBound - xRange.lowerBound)
                let y = gaussianPDF(x: x, mean: mean, stdDev: stdDev)
                
                // Map to canvas coordinates
                let canvasX = padding + CGFloat((x - xRange.lowerBound) / (xRange.upperBound - xRange.lowerBound)) * graphWidth
                let canvasY = (height - padding) - CGFloat(y / maxPDF) * graphHeight * 0.9
                
                if i == 0 {
                    curvePath.move(to: CGPoint(x: canvasX, y: canvasY))
                } else {
                    curvePath.addLine(to: CGPoint(x: canvasX, y: canvasY))
                }
            }
            
            // Fill under curve
            var fillPath = curvePath
            fillPath.addLine(to: CGPoint(x: width - padding, y: height - padding))
            fillPath.addLine(to: CGPoint(x: padding, y: height - padding))
            fillPath.closeSubpath()
            
            context.fill(fillPath, with: .color(.blue.opacity(0.2)))
            context.stroke(curvePath, with: .color(.blue), lineWidth: 2.5)
            
            // Draw mean line
            let meanX = padding + CGFloat((mean - xRange.lowerBound) / (xRange.upperBound - xRange.lowerBound)) * graphWidth
            let meanPath = Path { path in
                path.move(to: CGPoint(x: meanX, y: height - padding))
                path.addLine(to: CGPoint(x: meanX, y: padding))
            }
            context.stroke(meanPath, with: .color(.red.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
            
            // Draw mu label
            let muText = Text("μ").font(.caption).foregroundStyle(.red)
            context.draw(muText, at: CGPoint(x: meanX, y: height - padding + 12))
        }
    }
    
    private func gaussianPDF(x: Double, mean: Double, stdDev: Double) -> Double {
        let coefficient = 1.0 / (stdDev * sqrt(2 * .pi))
        let exponent = -pow(x - mean, 2) / (2 * pow(stdDev, 2))
        return coefficient * exp(exponent)
    }
}
