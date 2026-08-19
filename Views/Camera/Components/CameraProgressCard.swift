import SwiftUI

struct CameraProgressCard: View {
    let capturedCount: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(.white.opacity(0.15), lineWidth: 4).frame(width: 60, height: 60)
                VStack(spacing: 0) {
                    Text("\(capturedCount)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("frames")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Captured").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.6))
                Text("\(capturedCount) frame\(capturedCount == 1 ? "" : "s")").font(.callout.bold()).foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(20)
        .glassEffect(cornerRadius: 16)
    }
}
