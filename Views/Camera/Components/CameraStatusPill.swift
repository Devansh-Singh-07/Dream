import SwiftUI

struct CameraStatusPill: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.fill")
                .font(.callout.weight(.bold))
                .foregroundStyle(Color.appBlue)

            Text("\(count)")
                .font(.system(.callout, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("Frames")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassCapsule(accent: .appBlue)
    }
}
