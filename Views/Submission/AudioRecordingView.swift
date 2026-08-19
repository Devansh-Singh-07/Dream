import SwiftUI
import AVFoundation

struct AudioRecordingView: View {
    let frames: [FrameData]
    let onSave: (Data?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var recordingTime: TimeInterval = 0
    @State private var currentFrameIndex = 0
    @State private var isPlayingAnimation = false
    
    @State private var recordingTask: Task<Void, Never>?
    @State private var animationTask: Task<Void, Never>?
    
    var animationDuration: TimeInterval {
        frames.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CandyBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Icon
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.appRed.opacity(0.15))
                                    .frame(width: 76, height: 76)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Color.appRed)
                                    .symbolEffect(.pulse, options: .repeating, value: audioRecorder.isRecording)
                            }
                            Spacer()
                        }
                        .padding(.top, 12)
                        
                        // Animation Preview Card
                        ZStack {
                            Color.black
                            
                            if !frames.isEmpty {
                                let safeIndex = min(currentFrameIndex, max(0, frames.count - 1))
                                if let currentImage = frames[safeIndex].image {
                                    Image(uiImage: currentImage)
                                        .resizable()
                                        .scaledToFit()
                                        .transition(.opacity)
                                }
                            }
                            
                            if !isPlayingAnimation && !audioRecorder.isRecording {
                                ZStack {
                                    Color.black.opacity(0.45)
                                    
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.appBlue)
                                                .frame(width: 64, height: 64)
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                        .shadow(color: .appBlue.opacity(0.4), radius: 10, x: 0, y: 5)
                                        
                                        Text("Animation plays while recording")
                                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.9))
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                        .frame(height: UIScreen.main.bounds.width * 0.6)
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal, 24)
                        
                        // Recording Status Card
                        VStack(spacing: 16) {
                            Text(timeString(recordingTime))
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(audioRecorder.isRecording ? Color.appRed : .primary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .frame(maxWidth: .infinity)
                            
                            HStack(spacing: 10) {
                                if audioRecorder.isRecording {
                                    ZStack {
                                        Circle()
                                            .fill(Color.appRed)
                                            .frame(width: 14, height: 14)
                                        
                                        Circle()
                                            .stroke(Color.appRed, lineWidth: 3)
                                            .frame(width: 26, height: 26)
                                            .scaleEffect(audioRecorder.isRecording ? 1.5 : 1.0)
                                            .opacity(audioRecorder.isRecording ? 0.0 : 1.0)
                                            .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), 
                                                     value: audioRecorder.isRecording)
                                    }
                                    
                                    Text("Recording Studio Active…")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .foregroundStyle(Color.appRed)
                                } else if audioRecorder.hasRecording {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.appGreen)
                                    
                                    Text("Voiceover Recorded!")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .foregroundStyle(Color.appGreen)
                                } else {
                                    Image(systemName: "mic.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Tap Record to Start!")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: .cornerRadius))
                        .shadow(color: .appRed.opacity(0.08), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 24)
                        
                        // Studio Voice Tips Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.appYellow)
                                Text("Studio Voice Tips")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TipRow(iconSystemName: "arrow.triangle.2.circlepath", text: "Animation loops automatically while you record")
                                TipRow(iconSystemName: "speaker.wave.2.fill", text: "Speak clearly and bring your characters to life!")
                                TipRow(iconSystemName: "timer", text: "One loop is \(String(format: "%.1f", animationDuration))s long")
                            }
                        }
                        .padding(20)
                        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: .cornerRadius))
                        .shadow(color: .appYellow.opacity(0.08), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 24)
                        
                        // Control Buttons
                        VStack(spacing: 14) {
                            Button(action: toggleRecording) {
                                HStack(spacing: 10) {
                                    Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : (audioRecorder.hasRecording ? "arrow.counterclockwise" : "mic.circle.fill"))
                                        .font(.title3.weight(.bold))
                                    
                                    Text(audioRecorder.isRecording ? "Stop Recording" : audioRecorder.hasRecording ? "Re-record Voiceover" : "Start Recording")
                                        .font(.system(.title3, design: .rounded, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    audioRecorder.isRecording 
                                        ? AnyShapeStyle(Color.appRed) 
                                        : AnyShapeStyle(LinearGradient(colors: [.appRed, .appPink], startPoint: .leading, endPoint: .trailing))
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color.appRed.opacity(0.35), radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(BubbleButtonStyle())
                            
                            if audioRecorder.hasRecording {
                                Button(action: saveAndContinue) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark")
                                            .font(.headline.weight(.bold))
                                        Text("Save Narration")
                                            .font(.system(.title3, design: .rounded, weight: .bold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.appGreen, in: Capsule())
                                    .shadow(color: Color.appGreen.opacity(0.35), radius: 12, x: 0, y: 6)
                                }
                                .buttonStyle(BubbleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Voiceover Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        stopAnimation()
                        onSave(nil)
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                audioRecorder.setupRecorder()
            }
            .onDisappear {
                recordingTask?.cancel()
                animationTask?.cancel()
                stopAnimation()
                audioRecorder.cleanup()
            }
        }
    }
    
    private func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            recordingTask?.cancel()
            stopAnimation()
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            audioRecorder.startRecording()
            recordingTime = 0
            
            recordingTask = Task { @MainActor in
                while !Task.isCancelled && audioRecorder.isRecording {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { break }
                    recordingTime += 0.1
                }
            }
            
            startAnimation()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func startAnimation() {
        isPlayingAnimation = true
        currentFrameIndex = 0
        advanceFrame()
    }

    private func advanceFrame() {
        guard isPlayingAnimation, currentFrameIndex < frames.count else { return }
        
        let duration = frames[currentFrameIndex].duration
        
        animationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, isPlayingAnimation else { return }
            
            if currentFrameIndex < frames.count - 1 {
                currentFrameIndex += 1
            } else {
                currentFrameIndex = 0
            }
            advanceFrame()
        }
    }
    
    private func stopAnimation() {
        isPlayingAnimation = false
        animationTask?.cancel()
        currentFrameIndex = 0
    }
    
    private func saveAndContinue() {
        stopAnimation()
        
        if let audioData = audioRecorder.getRecordingData() {
            onSave(audioData)
        } else {
            onSave(nil)
        }
        dismiss()
    }
    
    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let fraction = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, fraction)
    }
}

struct TipRow: View {
    let iconSystemName: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconSystemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.appBlue)
            
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AudioRecordingView(
        frames: [],
        onSave: { _ in }
    )
}
