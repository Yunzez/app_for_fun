import SwiftUI

struct ProgressRing: View {
    let progress: Double      // 0...1
    let accent: Color
    var lineWidth: CGFloat = 3

    var body: some View {
        let clamped = max(0, min(1, progress))
        ZStack {
            Circle()
                .stroke(accent.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
