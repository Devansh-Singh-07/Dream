import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Immersive Editor (Clean & Elegant Apple Studio UX)

struct PreviewView: View {
    @Binding var frames: [FrameData]
    var existingMovie: Movie?
    var audioData: Data? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var currentFrameIndex = 0
    @State private var selectedFrameIndex: Int? = nil
    @State private var isPlaying = false
    @State private var showingSaveConfirmation = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recordedAudio: Data?
    @State private var selectedTool: EditorTool = .timing
    
    @State private var totalDuration: Double = 0
    @State private var playbackTask: Task<Void, Never>?
    
    // Gamification
    @State private var celebrationQueue = CelebrationQueue()
    @State private var hasAwardedTimingXP: Bool = false
    @State private var previousRecordedAudio: Data? = nil

    // Story Canvas
    @State private var showingScriptPanel = false
    @State private var storyScript: String = ""
    @State private var storySketch: Data? = nil

    enum EditorTool: String, CaseIterable, Identifiable {
        case timing = "Speed"
        case audio = "Voiceover"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .timing: return "speedometer"
            case .audio: return "mic.fill"
            }
        }
    }

    var hasAudio: Bool { recordedAudio != nil || audioData != nil }
    var currentAudioData: Data? { recordedAudio ?? audioData }

    var body: some View {
        ZStack {
            // Dark studio background
            Color(red: 0.07, green: 0.07, blue: 0.09)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // ── Top Bar ───────────────────────────
                editorTopBar
                
                // ── Canvas Video Player ───────────────
                cinemaCanvas
                    .layoutPriority(1)
                
                // ── Filmstrip Timeline ────────────────
                filmstripTimeline
                
                // ── Segmented Control Bar ──────────────
                toolSegmentedControl
                
                // ── Active Control Drawer ─────────────
                activeToolDrawer
                    .padding(.bottom, 8)
            }
            .padding(.top, 8)
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .statusBarHidden(isPlaying)
        .modifier(PreviewLifecycleModifier(
            frames: frames,
            totalDuration: $totalDuration,
            showingSaveConfirmation: $showingSaveConfirmation,
            onStopPlayback: stopPlayback,
            onCleanup: {
                stopPlayback()
                playbackTask?.cancel()
                audioPlayer?.stop()
                audioPlayer = nil
            },
            onDismiss: { dismiss() }
        ))
        .fullScreenCover(isPresented: $showingSaveConfirmation) {
            NavigationStack {
                SaveConfirmationView(frames: frames, existingMovie: existingMovie, audioData: currentAudioData)
            }
        }
        .onChange(of: recordedAudio) { oldValue, newValue in
            guard let _ = newValue else { return }
            let isFirstTime = (existingMovie?.audioNarration == nil && previousRecordedAudio == nil)
            awardNarrationXP(isFirstTime: isFirstTime)
            previousRecordedAudio = newValue
        }
        .onChange(of: frames) { _, newFrames in
            checkCustomTimingAward(frames: newFrames)
        }
        .celebrationQueue(celebrationQueue)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTool)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPlaying)
        .onAppear {
            storyScript = existingMovie?.storyScript ?? ""
            storySketch = existingMovie?.storySketch
        }
        .sheet(isPresented: $showingScriptPanel, onDismiss: saveScriptToMovie) {
            StoryScriptPanel(script: $storyScript, sketchData: $storySketch)
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Clean Top Bar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var editorTopBar: some View {
        HStack {
            // Close / Back button
            Button(action: {
                hapticFeedback(.light)
                stopPlayback()
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("Studio")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassCapsule()
            }
            
            Spacer()

            // Script toggle button
            ScriptToggleButton(
                hasScript: !storyScript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                isActive: showingScriptPanel,
                action: {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                        showingScriptPanel.toggle()
                    }
                }
            )

            Spacer()
            
            // Single Combined Info Pill
            HStack(spacing: 8) {
                Label("\(currentFrameIndex + 1)/\(frames.count)", systemImage: "film")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .monospacedDigit()
                
                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
                
                Label(String(format: "%.1fs", totalDuration), systemImage: "clock")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .monospacedDigit()
                
                if hasAudio {
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Image(systemName: "waveform")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.appGreen)
                }
            }
            .foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassCapsule()
            
            Spacer()
            
            // Export button
            if frames.count > 0 {
                Button(action: {
                    hapticFeedback(.medium)
                    showingSaveConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Text("Export")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.appGreen, Color.appGreen.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color.appGreen.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(BubbleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }

    // ── Script & sketch persistence helper ──
    private func saveScriptToMovie() {
        existingMovie?.storyScript = storyScript
        existingMovie?.storySketch = storySketch
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Cinema Canvas
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var cinemaCanvas: some View {
        ZStack {
            Color.black
            
            if !frames.isEmpty {
                let safeIndex = min(currentFrameIndex, frames.count - 1)
                if let img = frames[safeIndex].image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .transition(.opacity)
                }
            }
            
            // Floating play button overlay
            if !isPlaying {
                Button(action: {
                    hapticFeedback(.light)
                    togglePlayback()
                }) {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.5))
                            .frame(width: 68, height: 68)
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 68, height: 68)
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    }
                }
                .buttonStyle(BubbleButtonStyle())
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            hapticFeedback(.light)
            togglePlayback()
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Streamlined Timeline Strip
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var filmstripTimeline: some View {
        VStack(spacing: 4) {
            // Playhead indicator
            Capsule()
                .fill(Color.appBlue)
                .frame(width: 20, height: 3)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                            filmstripFrame(frame: frame, index: index)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, UIScreen.main.bounds.width / 2 - 30)
                }
                .onChange(of: currentFrameIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .frame(height: 58)
        }
        .padding(.vertical, 6)
        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
    }
    
    private func filmstripFrame(frame: FrameData, index: Int) -> some View {
        let isCurrent = currentFrameIndex == index
        let isSelected = selectedFrameIndex == index
        let isCustomSpeed = abs(frame.duration - 0.1) > 0.001
        
        return Button(action: {
            hapticFeedback(.light)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedFrameIndex = index
                currentFrameIndex = index
            }
        }) {
            ZStack(alignment: .bottomTrailing) {
                if let image = frame.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipped()
                } else {
                    Color.gray.opacity(0.3)
                        .frame(width: 52, height: 52)
                }
                
                // Speed pill if custom
                if isCustomSpeed {
                    Text(String(format: "%.1fs", frame.duration))
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.appBlue, in: Capsule())
                        .padding(3)
                }
                
                // Frame highlight ring
                if isCurrent {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appBlue, lineWidth: 3)
                } else if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appBlue, lineWidth: 2)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(isCurrent ? 1.08 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isCurrent)
        }
        .buttonStyle(.plain)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Tool Segmented Control Bar
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var toolSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(EditorTool.allCases) { tool in
                Button(action: {
                    hapticFeedback(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTool = tool
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tool.icon)
                            .font(.system(size: 13, weight: .bold))
                        Text(tool.rawValue)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                    }
                    .foregroundStyle(selectedTool == tool ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTool == tool
                            ? AnyShapeStyle(Color.appBlue)
                            : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(red: 0.14, green: 0.14, blue: 0.16), in: Capsule())
        .padding(.horizontal, 20)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Active Control Drawer
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private var activeToolDrawer: some View {
        VStack {
            switch selectedTool {
            case .timing:
                PreviewTimingEditor(
                    frames: $frames,
                    selectedFrameIndex: $selectedFrameIndex,
                    onDeleteFrame: deleteFrame,
                    isDarkMode: true
                )
                .transition(.opacity)
            case .audio:
                PreviewAudioEditor(
                    recordedAudio: $recordedAudio,
                    maxDuration: totalDuration,
                    onRecordingStarted: startPlayback,
                    onRecordingStopped: stopPlayback,
                    isDarkMode: true
                )
                .transition(.opacity)
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Playback Engine
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func togglePlayback() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            isPlaying ? stopPlayback() : startPlayback()
        }
    }

    private func startPlayback() {
        isPlaying = true
        currentFrameIndex = 0
        selectedFrameIndex = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        if let data = currentAudioData {
            do {
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch { print("Audio playback error: \(error)") }
        }
        advanceFrame()
    }

    private func advanceFrame() {
        guard isPlaying, currentFrameIndex < frames.count else { return }
        let duration = frames[currentFrameIndex].duration
        
        playbackTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, self.isPlaying else { return }
            
            withAnimation(.easeInOut(duration: 0.1)) {
                if self.currentFrameIndex < self.frames.count - 1 {
                    self.currentFrameIndex += 1
                    self.advanceFrame()
                } else {
                    self.stopPlayback()
                }
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        playbackTask?.cancel()
        audioPlayer?.stop()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentFrameIndex = 0
        }
    }

    private func deleteFrame(at index: Int) {
        guard frames.count > 1 else { return }
        stopPlayback()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if currentFrameIndex >= frames.count - 1 {
                currentFrameIndex = max(frames.count - 2, 0)
            } else if currentFrameIndex > index {
                currentFrameIndex -= 1
            }
            frames.remove(at: index)
            selectedFrameIndex = nil
        }
        
        if let movie = existingMovie {
            movie.framesData = frames
            try? modelContext.save()
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Gamification
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func awardNarrationXP(isFirstTime: Bool) {
        let profile = StudentProfile.fetchOrCreate(context: modelContext)
        let xpResult = profile.awardXP(XPCalculator.pointsForNarration(isFirstTime: isFirstTime))
        
        var unlockedBadges: [BadgeDefinition] = []
        if isFirstTime {
            if let _ = profile.awardBadge("storyteller") {
                unlockedBadges.append(.storyteller)
            }
        } else {
            if let _ = profile.awardBadge("perfectionist") {
                unlockedBadges.append(.perfectionist)
            }
        }
        
        try? modelContext.save()
        
        let overallResult = XPAwardResult(
            xpAwarded: xpResult.xpAwarded,
            levelBefore: xpResult.levelBefore,
            levelAfter: profile.level
        )
        celebrationQueue.enqueue(
            CelebrationQueue.eventsFrom(result: overallResult, unlockedBadges: unlockedBadges)
        )
    }
    
    private func checkCustomTimingAward(frames: [FrameData]) {
        guard !hasAwardedTimingXP else { return }
        let defaultDuration: Double = 0.1
        let customCount = frames.filter { abs($0.duration - defaultDuration) > 0.001 }.count
        
        guard customCount >= 3 else { return }
        
        let profile = StudentProfile.fetchOrCreate(context: modelContext)
        let xpResult = profile.awardXP(XPCalculator.pointsForCustomTiming())
        
        var unlockedBadges: [BadgeDefinition] = []
        if customCount >= 5 {
            if let _ = profile.awardBadge("directors_cut") {
                unlockedBadges.append(.directorsCut)
            }
        }
        
        try? modelContext.save()
        hasAwardedTimingXP = true
        
        let overallResult = XPAwardResult(
            xpAwarded: xpResult.xpAwarded,
            levelBefore: xpResult.levelBefore,
            levelAfter: profile.level
        )
        let timingToast = AchievementToastItem(
            title: "Nice Timing!",
            icon: "timer",
            xpReward: XPCalculator.pointsForCustomTiming(),
            message: "Customized frame durations"
        )
        celebrationQueue.enqueue(
            CelebrationQueue.eventsFrom(
                result: overallResult,
                unlockedBadges: unlockedBadges,
                fallbackToast: timingToast
            )
        )
    }
}

// MARK: - Lifecycle Modifier

struct PreviewLifecycleModifier: ViewModifier {
    let frames: [FrameData]
    @Binding var totalDuration: Double
    @Binding var showingSaveConfirmation: Bool
    let onStopPlayback: () -> Void
    let onCleanup: () -> Void
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                totalDuration = frames.reduce(0) { $0 + $1.duration }
            }
            .onChange(of: frames.count) { _, _ in
                totalDuration = frames.reduce(0) { $0 + $1.duration }
            }
            .onDisappear {
                onCleanup()
            }
            .onReceive(NotificationCenter.default.publisher(for: .dismissToHome)) { _ in
                showingSaveConfirmation = false
                onDismiss()
            }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var frames = (1...20).map { _ in
        FrameData(image: UIImage(systemName: "photo")!)
    }
    return PreviewView(frames: $frames, existingMovie: nil)
}
