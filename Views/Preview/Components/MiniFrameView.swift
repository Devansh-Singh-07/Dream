import SwiftUI

// MARK: - Mini Frame Thumbnail
struct MiniFrameView: View {
    let frame: FrameData
    let index: Int
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Color(.systemGray6)
                    if let image = frame.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 46, height: 46)
                            .clipped()
                    }
                    if isCurrent {
                        RoundedRectangle(cornerRadius: 10).fill(Color.appBlue.opacity(0.25))
                    }
                }
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? Color.appBlue : (isCurrent ? Color.appGreen : Color(.systemGray4)),
                            lineWidth: isSelected ? 3 : (isCurrent ? 2 : 1)
                        )
                }

                VStack(spacing: 1) {
                    Text("\(index + 1)")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(isSelected ? Color.appBlue : .primary)
                    Text(String(format: "%.1fs", frame.duration))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(isSelected ? Color.appBlue : .secondary)
                        .monospacedDigit()
                }
            }
        }
        .buttonStyle(BubbleButtonStyle())
    }
}
