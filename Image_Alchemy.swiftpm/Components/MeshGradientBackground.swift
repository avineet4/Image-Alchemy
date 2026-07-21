import SwiftUI

// Reusable mesh-style background
struct MeshGradientBackgroundDark: View {

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince1970
            let offsetX = Float(sin(time)) * 0.1
            let offsetY = Float(cos(time)) * 0.1
            
            MeshGradient(
                width: 4,
                height: 4,
                points: [
                    [0.0, 0.0],
                    [0.3, 0.0],
                    [0.7, 0.0],
                    [1.0, 0.0],
                    [0.0, 0.3],
                    [0.2 + offsetX, 0.4 + offsetY],
                    [0.7 + offsetX, 0.2 + offsetY],
                    [1.0, 0.3],
                    [0.0, 0.7],
                    [0.3 + offsetX, 0.8],
                    [0.7 + offsetX, 0.6],
                    [1.0, 0.7],
                    [0.0, 1.0],
                    [0.3, 1.0],
                    [0.7, 1.0],
                    [1.0, 1.0]
                ],
                colors: [
                    .purple, .indigo, .purple, .black,
                    .black, .purple, .black, .black,
                    .black, .black, .black, .black,
                    .black, .black, .black, .purple
                ]
            )
        }
        .ignoresSafeArea()
    }
}

struct MeshGradientBackgroundLight: View {

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSince1970
            let offsetX = Float(sin(time)) * 0.1
            let offsetY = Float(cos(time)) * 0.1
            
            MeshGradient(
                width: 4,
                height: 4,
                points: [
                    [0.0, 0.0],
                    [0.3, 0.0],
                    [0.7, 0.0],
                    [1.0, 0.0],
                    [0.0, 0.3],
                    [0.2 + offsetX, 0.4 + offsetY],
                    [0.7 + offsetX, 0.2 + offsetY],
                    [1.0, 0.3],
                    [0.0, 0.7],
                    [0.3 + offsetX, 0.8],
                    [0.7 + offsetX, 0.6],
                    [1.0, 0.7],
                    [0.0, 1.0],
                    [0.3, 1.0],
                    [0.7, 1.0],
                    [1.0, 1.0]
                ],
                colors: [
                    .white, .mint, .white, .cyan,
                    .pink, .white, .mint, .white,
                    .white, .pink, .white, .mint,
                    .mint, .white, .cyan, .white
                ]
            )
        }
        .ignoresSafeArea()
    }
}


#Preview {
    NavigationStack {
        ZStack {
            MeshGradientBackgroundDark()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Mesh Gradient")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Reusable background for Image Alchemy")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    ZStack {
        MeshGradientBackgroundLight()

        VStack(spacing: 16) {
            Text("Mesh Gradient")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Reusable background for Image Alchemy")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
