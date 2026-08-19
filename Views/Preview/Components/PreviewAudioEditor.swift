import SwiftUI
import AVFoundation

// MARK: - Apple Voice Memos Style Voiceover Recorder
struct PreviewAudioEditor: View {
    @Binding var recordedAudio: Data?
    var maxDuration: Double = 0        // 0 = unlimited
    var onRecordingStarted: () -> Void = {}
    var onRecordingStopped: () -> Void = {}
    var isDarkMode: Bool = false

    @StateObject private var recorder = AudioRecorder()

    @State private var recordingTime: TimeInterval = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingBack = false
    @State private var waveformLevels: [CGFloat] = Array(repeating: 0.12, count: 32)
    @State private var playbackProgress: Double = 0
    @State private var playbackDuration: Double = 0
    
    @State private var recordingTask: Task<Void, Never>?
    @State private var waveformTask: Task<Void, Never>?
    @State private var playbackTask: Task<Void, Never>?

    private var state: RecordState {
        if recorder.isRecording { return .recording }
        if recorder.hasRecording || recordedAudio != nil { return .recorded }
        return .idle
    }

    enum RecordState { case idle, recording, recorded }

    var body: some View {
        VStack(spacing: 8) {
            // ── 1. Voice Memos Digital Timer & Status ──
            VStack(spacing: 1) {
                Text(timeString(recordingTime > 0 ? recordingTime : (audioPlayer?.duration ?? 0)))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(state == .recording ? Color.red : .white)
                    .contentTransition(.numericText())

                Text(statusText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            // ── 2. Voice Memos Animated Audio Waveform ──
            voiceMemosWaveform
                .frame(height: 28)
                .padding(.horizontal, 8)

            // ── 3. Voice Memos Control Deck ──
            HStack(spacing: 28) {
                // Left: Retake / Clear
                if state == .recorded && !recorder.isRecording {
                    Button(action: reRecord) {
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            Text("Retake")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .buttonStyle(BubbleButtonStyle())
                } else {
                    Color.clear
                        .frame(width: 36, height: 36)
                }

                // Center: Iconic Voice Memos Record Button
                voiceMemosRecordButton

                // Right: Play / Listen Back
                if state == .recorded && !recorder.isRecording {
                    Button(action: togglePlayback) {
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: isPlayingBack ? "pause.fill" : "play.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.appBlue)
                                    .offset(x: isPlayingBack ? 0 : 1)
                            }
                            Text(isPlayingBack ? "Pause" : "Listen")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .buttonStyle(BubbleButtonStyle())
                } else {
                    Color.clear
                        .frame(width: 36, height: 36)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            recorder.setupRecorder()
            if let data = recordedAudio {
                setupPlayback(data)
            }
        }
        .onDisappear {
            stopAllTasks()
            audioPlayer?.stop()
            audioPlayer = nil
            if !recorder.hasRecording { recorder.cleanup() }
        }
    }

    // MARK: - Voice Memos Waveform View

    private var voiceMemosWaveform: some View {
        ZStack {
            // Waveform level bars
            HStack(spacing: 3) {
                ForEach(waveformLevels.indices, id: \.self) { i in
                    let level = waveformLevels[i]
                    RoundedRectangle(cornerRadius: 1)
                        .fill(barColor(for: i))
                        .frame(width: 3, height: max(3, level * 26))
                        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: level)
                }
            }
            .frame(maxWidth: .infinity)

            // Center red playhead / recording indicator line
            Rectangle()
                .fill(Color.red)
                .frame(width: 1.5, height: 28)
                .opacity(state == .recording || isPlayingBack ? 1.0 : 0.4)
        }
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }

    private func barColor(for index: Int) -> Color {
        if state == .recording {
            return Color.red.opacity(0.75 + 0.25 * Double(waveformLevels[index]))
        } else if isPlayingBack {
            let progressIndex = Int(playbackProgress * Double(waveformLevels.count))
            return index <= progressIndex ? Color.appBlue : Color.white.opacity(0.2)
        } else if state == .recorded {
            return Color.white.opacity(0.35)
        }
        return Color.white.opacity(0.15)
    }

    // MARK: - Iconic Voice Memos Record Button

    private var voiceMemosRecordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 2.5)
                    .frame(width: 48, height: 48)

                // Inner red morphing shape
                if recorder.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                        .transition(.scale)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 38, height: 38)
                        .transition(.scale)
                }
            }
        }
        .buttonStyle(BubbleButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: recorder.isRecording)
    }

    // MARK: - Status Readouts

    private var statusText: String {
        switch state {
        case .idle: return "Tap red button to record voiceover"
        case .recording: return "Recording Audio…"
        case .recorded: return isPlayingBack ? "Playing Voiceover" : "Voiceover Ready"
        }
    }

    private var statusColor: Color {
        switch state {
        case .idle: return .white.opacity(0.5)
        case .recording: return .red
        case .recorded: return isPlayingBack ? Color.appBlue : Color.appGreen
        }
    }

    // MARK: - Task Management & Actions

    private func stopAllTasks() {
        recordingTask?.cancel()
        waveformTask?.cancel()
        playbackTask?.cancel()
        recordingTask = nil
        waveformTask = nil
        playbackTask = nil
        waveformLevels = Array(repeating: 0.12, count: 32)
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stopRecording()
            stopAllTasks()
            onRecordingStopped()
            if let data = recorder.getRecordingData() {
                recordedAudio = data
                setupPlayback(data)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            audioPlayer?.stop()
            isPlayingBack = false
            recorder.startRecording()
            recordingTime = 0
            
            recordingTask = Task { @MainActor in
                while !Task.isCancelled && recorder.isRecording {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { break }
                    recordingTime += 0.1
                    
                    if maxDuration > 0 && recordingTime >= maxDuration {
                        toggleRecording()
                        break
                    }
                }
            }
            
            startWaveformAnimation()
            onRecordingStarted()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func reRecord() {
        audioPlayer?.stop()
        isPlayingBack = false
        recordedAudio = nil
        recorder.cleanup()
        recorder.setupRecorder()
        recordingTime = 0
        playbackProgress = 0
        stopAllTasks()
    }

    private func togglePlayback() {
        guard let player = audioPlayer else { return }
        if isPlayingBack {
            player.pause()
            isPlayingBack = false
            playbackTask?.cancel()
        } else {
            player.play()
            isPlayingBack = true
            startPlaybackTimer()
        }
    }

    private func setupPlayback(_ data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            playbackDuration = audioPlayer?.duration ?? 0
        } catch { print("Audio setup error: \(error)") }
    }

    private func startWaveformAnimation() {
        waveformTask = Task { @MainActor in
            while !Task.isCancelled && recorder.isRecording {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { break }
                let newLevels = (0..<32).map { _ in CGFloat.random(in: 0.15...1.0) }
                withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                    waveformLevels = newLevels
                }
            }
        }
    }

    private func startPlaybackTimer() {
        playbackTask = Task { @MainActor in
            while !Task.isCancelled && isPlayingBack {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled, let player = audioPlayer else { break }
                if player.isPlaying {
                    playbackProgress = player.currentTime / max(0.1, player.duration)
                } else {
                    isPlayingBack = false
                    playbackProgress = 0
                    break
                }
            }
        }
    }

    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let fraction = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, fraction)
    }
}
