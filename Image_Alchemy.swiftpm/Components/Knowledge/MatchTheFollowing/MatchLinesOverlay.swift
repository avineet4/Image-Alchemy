import SwiftUI

struct MatchItemFrame: Equatable {
    let isLeft: Bool
    let index: Int
    let midX: Double
    let midY: Double
    let minX: Double
    let maxX: Double
}

struct MatchFramePreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [MatchItemFrame] = []
    static func reduce(value: inout [MatchItemFrame], nextValue: () -> [MatchItemFrame]) {
        value.append(contentsOf: nextValue())
    }
}

private let matchLineColor = Color(red: 0.56, green: 0.49, blue: 0.43)

struct MatchLinesOverlay: View {
    let userMatches: [Int: Int]
    let itemFrames: [MatchItemFrame]
    let hasChecked: Bool
    let pairs: [MatchPair]
    let rightItems: [String]
    var lineReveal: Double = 1
    
    private var leftPositions: [Int: CGPoint] {
        Dictionary(uniqueKeysWithValues: itemFrames.filter(\.isLeft).map { ($0.index, CGPoint(x: $0.maxX, y: $0.midY)) })
    }
    
    private var rightPositions: [Int: CGPoint] {
        Dictionary(uniqueKeysWithValues: itemFrames.filter { !$0.isLeft }.map { ($0.index, CGPoint(x: $0.minX, y: $0.midY)) })
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: hasChecked)) { timelineContext in
            let phase = hasChecked ? 0 : CGFloat(timelineContext.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2) / 2) * 20
            Canvas { context, size in
                drawLines(context: context, dashPhase: phase)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func drawLines(context: GraphicsContext, dashPhase: CGFloat = 0) {
        for (leftIdx, rightIdx) in userMatches {
            guard let start = leftPositions[leftIdx],
                  let end = rightPositions[rightIdx] else { continue }
            
            let isCorrect = rightItems[rightIdx] == pairs[leftIdx].rightItem
            let color: Color = hasChecked
                ? (isCorrect ? Color.green : Color.red)
                : matchLineColor
            let lineWidth: CGFloat = hasChecked ? 3 : 2.5
            let opacity = hasChecked ? 0.9 : 0.75
            let reveal = min(1, max(0, lineReveal))
            
            // Smoother S-curve: control points further from endpoints
            let dx = end.x - start.x
            let control1 = CGPoint(x: start.x + dx * 0.5, y: start.y)
            let control2 = CGPoint(x: start.x + dx * 0.5, y: end.y)
            
            var path = Path()
            path.move(to: start)
            path.addCurve(to: end, control1: control1, control2: control2)
            
            let strokeColor = color.opacity(opacity * reveal)
            if hasChecked {
                // Solid stroke with soft glow behind
                let glowColor = color.opacity(opacity * 0.4)
                context.stroke(path, with: .color(glowColor), lineWidth: lineWidth + 3)
                context.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)
            } else {
                // Dashed stroke with animated phase
                let strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: [8, 6], dashPhase: dashPhase)
                context.stroke(path, with: .color(strokeColor), style: strokeStyle)
            }
        }
    }
}
