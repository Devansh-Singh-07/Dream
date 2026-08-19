import SwiftUI

// MARK: - Timeline Strip
struct PreviewTimeline: View {
    @Binding var frames: [FrameData]
    @Binding var selectedFrameIndex: Int?
    @Binding var currentFrameIndex: Int
    let isPlaying: Bool
    let onTogglePlayback: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Button(action: onTogglePlayback) {
                    ZStack {
                        Circle().fill(Color.appBlue).frame(width: 34, height: 34)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.caption.bold()).foregroundStyle(.white)
                    }
                }
                .buttonStyle(BubbleButtonStyle())

                VStack(alignment: .leading, spacing: 2) {
                    Label("Timeline", systemImage: "film")
                        .font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(.primary)
                    Text("Tap a frame to edit its speed")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: { selectedFrameIndex = nil }) {
                    Text("Deselect")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.appBlue)
                }
                .buttonStyle(.plain)
                .opacity(selectedFrameIndex != nil ? 1 : 0)
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 24)

            // Scrollable frames
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                            MiniFrameView(
                                frame: frame,
                                index: index,
                                isSelected: selectedFrameIndex == index,
                                isCurrent: currentFrameIndex == index
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedFrameIndex = index
                                    currentFrameIndex = index
                                }
                            }
                            .id(index)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 60)
                .onChange(of: currentFrameIndex) { _, newIndex in
                    withAnimation { proxy.scrollTo(newIndex, anchor: .center) }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.bottom, 4)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous))
        .shadow(color: .appBlue.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
}
