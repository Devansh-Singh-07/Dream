import SwiftUI

// MARK: - Timing Editor Panel (Enriched Apple Photos Style)
struct PreviewTimingEditor: View {
    @Binding var frames: [FrameData]
    @Binding var selectedFrameIndex: Int?
    let onDeleteFrame: (Int) -> Void
    var isDarkMode: Bool = true

    @State private var customSpeedText: String = ""

    private struct SpeedPreset: Identifiable {
        let id = UUID()
        let label: String
        let sublabel: String
        let icon: String
        let value: Double
    }

    private let presets: [SpeedPreset] = [
        SpeedPreset(label: "0.1s", sublabel: "10 fps", icon: "bolt.fill", value: 0.1),
        SpeedPreset(label: "0.2s", sublabel: "5 fps", icon: "hare.fill", value: 0.2),
        SpeedPreset(label: "0.5s", sublabel: "2 fps", icon: "figure.walk", value: 0.5),
        SpeedPreset(label: "1.0s", sublabel: "1 fps", icon: "tortoise.fill", value: 1.0)
    ]

    private var currentDuration: Double {
        if let index = selectedFrameIndex, index < frames.count {
            return frames[index].duration
        }
        return frames.first?.duration ?? 0.1
    }

    private var calculatedFPS: Double {
        guard currentDuration > 0 else { return 10.0 }
        return 1.0 / currentDuration
    }

    private var animationFeelText: String {
        if calculatedFPS >= 12 {
            return "⚡ Fast & Fluid Animation"
        } else if calculatedFPS >= 8 {
            return "✨ Smooth Stop-Motion Pace"
        } else if calculatedFPS >= 4 {
            return "🧱 Classic Claymation Timing"
        } else {
            return "🐢 Dramatic Hold / Slow Motion"
        }
    }

    private var isCustomValue: Bool {
        !presets.contains(where: { abs(currentDuration - $0.value) < 0.02 })
    }

    var body: some View {
        VStack(spacing: 8) {
            // ── 1. Contextual Header Row ──
            HStack {
                if let index = selectedFrameIndex, index < frames.count {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.appBlue)
                        Text("Frame \(index + 1) Duration")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Apply to all frames button
                    Button(action: {
                        hapticFeedback(.light)
                        applySpeed(currentDuration, applyToAll: true)
                    }) {
                        Text("Apply to All")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appBlue.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(BubbleButtonStyle())

                    // Delete frame button
                    Button(action: {
                        onDeleteFrame(index)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10, weight: .bold))
                            Text("Delete")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color.appRed)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appRed.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(BubbleButtonStyle())
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.appBlue)
                        Text("All Frames Speed")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button(action: {
                        hapticFeedback(.light)
                        applySpeed(0.1, applyToAll: true)
                    }) {
                        Text("Reset (10 FPS)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08), in: Capsule())
                    }
                    .buttonStyle(BubbleButtonStyle())
                }
            }

            // ── 2. Middle: Stop-Motion Pace & FPS Badge ──
            HStack {
                HStack(spacing: 6) {
                    Text(String(format: "%.1f FPS", calculatedFPS))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.appBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.appBlue.opacity(0.15), in: Capsule())

                    Text(animationFeelText)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Text(String(format: "%.1fs total", Double(frames.count) * currentDuration))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 2)

            // ── 3. Bottom: Presets & Custom Speed Textbox ──
            HStack(spacing: 6) {
                // Preset Buttons
                ForEach(presets) { preset in
                    let isSelected = abs(currentDuration - preset.value) < 0.02
                    Button(action: {
                        hapticFeedback(.light)
                        applySpeed(preset.value)
                    }) {
                        VStack(spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 9, weight: .bold))
                                Text(preset.label)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                            }

                            Text(preset.sublabel)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(isSelected ? .white.opacity(0.8) : .white.opacity(0.45))
                        }
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            isSelected
                                ? AnyShapeStyle(Color.appBlue)
                                : AnyShapeStyle(Color.white.opacity(0.08)),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(BubbleButtonStyle())
                }

                // Custom Speed Input Field
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        TextField("0.1", text: $customSpeedText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                            .frame(width: 34)
                            .foregroundStyle(.white)
                            .onChange(of: customSpeedText) { _, newText in
                                let cleaned = newText.replacingOccurrences(of: ",", with: ".")
                                if let val = Double(cleaned), val > 0 {
                                    applySpeed(max(0.01, min(10.0, val)), updateText: false)
                                }
                            }

                        Text("s")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Text("custom")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isCustomValue ? Color.appBlue : Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            syncText()
        }
        .onChange(of: selectedFrameIndex) { _, _ in
            syncText()
        }
        .onChange(of: frames) { _, _ in
            syncText()
        }
    }

    private func applySpeed(_ value: Double, applyToAll: Bool = false, updateText: Bool = true) {
        if applyToAll {
            for i in frames.indices {
                frames[i].duration = value
            }
        } else if let index = selectedFrameIndex, index < frames.count {
            frames[index].duration = value
        } else {
            for i in frames.indices {
                frames[i].duration = value
            }
        }
        if updateText {
            customSpeedText = String(format: "%.2f", value)
        }
    }

    private func syncText() {
        customSpeedText = String(format: "%.2f", currentDuration)
    }
}
