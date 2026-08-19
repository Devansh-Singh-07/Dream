import SwiftUI

struct FrameCounterPill: View {
    let count: Int
    let minFrames: Int

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(.blue.opacity(0.2)).frame(width: 32, height: 32)
                Image(systemName: "camera.fill").font(.caption).foregroundStyle(.blue)
            }
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(count)").font(.title3.bold()).foregroundStyle(.white).monospacedDigit()
                Text("/ \(minFrames)").font(.caption2).foregroundStyle(.white.opacity(0.6)).monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassCapsule()
    }
}
