import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

// MARK: - Movie Editor (Photos App Style Immersive Editor)

struct MovieEditorView: View {
    let movie: Movie

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Frame state (owned by editor, persisted to movie)
    @State private var frames: [FrameData] = []
    @State private var currentFrameIndex = 0
    @State private var selectedFrameIndex: Int? = nil

    // Playback
    @State private var isPlaying = false
    @State private var playbackTask: Task<Void, Never>?
    @State private var totalDuration: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recordedAudio: Data?

    // Tool selection & sheet state
    @State private var selectedTool: EditorTool = .timing
    @State private var isSheetExpanded: Bool = true

    // Presentation state
    @State private var showingCamera = false
    @State private var showingGallery = false
    @State private var showingSaveConfirmation = false

    // Story Canvas
    @State private var showingScriptPanel = false
    @State private var storyScript: String = ""
    @State private var storySketch: Data? = nil

    // Gallery picker
    @State private var selectedPhotos: [PhotosPickerItem] = []

    // Gamification
    @State private var celebrationQueue = CelebrationQueue()
    @State private var hasAwardedTimingXP: Bool = false
    @State private var previousRecordedAudio: Data? = nil

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

    var hasAudio: Bool { recordedAudio != nil || movie.audioNarration != nil }
    var currentAudioData: Data? { recordedAudio ?? movie.audioNarration }

    var body: some View {
        ZStack {
            // Pure black studio background (Photos app style)
            Color.black
                .ignoresSafeArea()

            if frames.isEmpty {
                emptyEditorState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
            } else {
                editorContent
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(movie.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            // ── Leading: Native Back / Close Button ──
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    hapticFeedback(.light)
                    stopPlayback()
                    saveProgress()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            // ── Trailing: Add Images, Story & Export ──
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Add Images Menu (Camera / Photos)
                Menu {
                    Button(action: {
                        hapticFeedback(.medium)
                        showingCamera = true
                    }) {
                        Label("Take with Camera", systemImage: "camera")
                    }

                    Button(action: {
                        hapticFeedback(.medium)
                        showingGallery = true
                    }) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.appBlue)
                }

                // Story Panel Button
                if !frames.isEmpty {
                    Button(action: {
                        hapticFeedback(.light)
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                            showingScriptPanel.toggle()
                        }
                    }) {
                        Image(systemName: "note.text")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(showingScriptPanel ? Color.appBlue : .white.opacity(0.85))
                    }
                }

                // Export Button
                if !frames.isEmpty {
                    Button(action: {
                        hapticFeedback(.medium)
                        showingSaveConfirmation = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.appGreen)
                    }
                }
            }
        }
        .statusBarHidden(isPlaying)
        .onAppear {
            loadMovieData()
        }
        .onDisappear {
            stopPlayback()
            playbackTask?.cancel()
            audioPlayer?.stop()
            audioPlayer = nil
        }
        .onChange(of: frames) { _, newFrames in
            totalDuration = newFrames.reduce(0) { $0 + $1.duration }
            checkCustomTimingAward(frames: newFrames)
        }
        .onChange(of: recordedAudio) { oldValue, newValue in
            guard let _ = newValue else { return }
            let isFirstTime = (movie.audioNarration == nil && previousRecordedAudio == nil)
            awardNarrationXP(isFirstTime: isFirstTime)
            previousRecordedAudio = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissToHome)) { _ in
            saveProgress()
            dismiss()
        }
        .fullScreenCover(isPresented: $showingCamera) {
            NavigationStack {
                CameraView(
                    existingMovie: movie,
                    initialFrames: frames,
                    onFramesCaptured: { newFrames in
                        handleCameraFrames(newFrames)
                    }
                )
            }
        }
        .photosPicker(
            isPresented: $showingGallery,
            selection: $selectedPhotos,
            maxSelectionCount: 50,
            matching: .images
        )
        .onChange(of: selectedPhotos) { _, newItems in
            handleGallerySelection(newItems)
        }
        .fullScreenCover(isPresented: $showingSaveConfirmation) {
            NavigationStack {
                SaveConfirmationView(frames: frames, existingMovie: movie, audioData: currentAudioData)
            }
        }
        .sheet(isPresented: $showingScriptPanel, onDismiss: saveScriptToMovie) {
            StoryScriptPanel(script: $storyScript, sketchData: $storySketch)
        }
        .celebrationQueue(celebrationQueue)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTool)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSheetExpanded)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPlaying)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Empty State (Pure Black Photos App Look)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var emptyEditorState: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.appBlue.opacity(0.12))
                        .frame(width: 110, height: 110)

                    Image(systemName: "film.stack")
                        .font(.system(size: 46))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.appBlue, .appPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce)
                }

                VStack(spacing: 8) {
                    Text("Ready to Animate!")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Capture new stop-motion frames with the Camera or import existing photos from your Gallery.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 440)
                }
            }

            // High-Affordance Action Cards
            HStack(spacing: 18) {
                // Camera Action Card
                Button(action: {
                    hapticFeedback(.medium)
                    showingCamera = true
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.appBlue.opacity(0.15))
                                .frame(width: 58, height: 58)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.appBlue)
                        }

                        VStack(spacing: 4) {
                            Text("Open Camera")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Shoot frame by frame with ghost overlay")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(22)
                    .frame(width: 220, height: 170)
                    .glassEffect(cornerRadius: 22, accent: Color.appBlue.opacity(0.3))
                }
                .buttonStyle(BubbleButtonStyle())

                // Gallery Action Card
                Button(action: {
                    hapticFeedback(.medium)
                    showingGallery = true
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.appPurple.opacity(0.15))
                                .frame(width: 58, height: 58)
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.appPurple)
                        }

                        VStack(spacing: 4) {
                            Text("Import Photos")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Select images from your Photo Library")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(22)
                    .frame(width: 220, height: 170)
                    .glassEffect(cornerRadius: 22, accent: Color.appPurple.opacity(0.3))
                }
                .buttonStyle(BubbleButtonStyle())
            }

            Spacer()
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Editor Content (Full-Screen Pure Black Viewport)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var editorContent: some View {
        VStack(spacing: 0) {
            // ── 1. Full-Screen Video Canvas on Pure Black (No box/border) ──
            cinemaCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── 2. Bottom Editing Sheet (Photos App Style Scrubber & Tools) ──
            bottomEditingSheet
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Cinema Canvas Player (Pure Black Full Screen, No Box)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var cinemaCanvas: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if !frames.isEmpty {
                    let safeIndex = min(currentFrameIndex, frames.count - 1)
                    if let img = frames[safeIndex].image {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                            .transition(.opacity)
                    }
                }

                // Floating Photos App Style Play Button Overlay
                if !isPlaying && !frames.isEmpty {
                    Button(action: {
                        hapticFeedback(.light)
                        togglePlayback()
                    }) {
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.6))
                                .frame(width: 64, height: 64)
                            Circle()
                                .stroke(.white.opacity(0.35), lineWidth: 2)
                                .frame(width: 64, height: 64)
                            Image(systemName: "play.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: 2)
                        }
                    }
                    .buttonStyle(BubbleButtonStyle())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture {
                if !frames.isEmpty {
                    hapticFeedback(.light)
                    togglePlayback()
                }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Bottom Editing Sheet (Photos App Style Inspector)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var bottomEditingSheet: some View {
        VStack(spacing: 12) {
            // ── Clean Centered Grabber Handle (Tap or swipe to collapse/expand) ──
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    hapticFeedback(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isSheetExpanded.toggle()
                    }
                }

            // ── Filmstrip Timeline with Details Directly Underneath ──
            filmstripTimeline
                .padding(.bottom, isSheetExpanded ? 0 : 6)

            // ── Expandable Tools Drawer ──
            if isSheetExpanded {
                VStack(spacing: 12) {
                    // Tool Segmented Control
                    toolSegmentedControl

                    // Active Tool Drawer
                    activeToolDrawer
                }
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.bottom, 24)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                topTrailingRadius: 24
            )
            .fill(.ultraThinMaterial)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    topTrailingRadius: 24
                )
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: -4)
        )
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    if value.translation.height > 30 && isSheetExpanded {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isSheetExpanded = false
                        }
                    } else if value.translation.height < -30 && !isSheetExpanded {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isSheetExpanded = true
                        }
                    }
                }
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Filmstrip Timeline
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var filmstripTimeline: some View {
        VStack(spacing: 6) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(frames.enumerated()), id: \.offset) { index, frame in
                            filmstripFrame(frame: frame, index: index)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onChange(of: currentFrameIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .frame(height: 56)

            // ── Frame & Time details under the filmstrip ──
            HStack(spacing: 6) {
                Label("Frame \(currentFrameIndex + 1) of \(frames.count)", systemImage: "film")
                    .monospacedDigit()
                Text("•")
                    .foregroundStyle(.white.opacity(0.3))
                Label(String(format: "%.1fs total", totalDuration), systemImage: "clock")
                    .monospacedDigit()
                if hasAudio {
                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))
                    Image(systemName: "waveform")
                        .foregroundStyle(Color.appGreen)
                }
                Spacer()
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(.white.opacity(0.65))
            .padding(.horizontal, 16)
            .padding(.top, 2)
        }
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

                if isCustomSpeed {
                    Text(String(format: "%.1fs", frame.duration))
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.appBlue, in: Capsule())
                        .padding(3)
                }

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
    // MARK: - Tool Segmented Control
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
                    .foregroundStyle(selectedTool == tool ? .white : .white.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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
        .background(Color.white.opacity(0.08), in: Capsule())
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Active Tool Drawer
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var activeToolDrawer: some View {
        ZStack {
            if selectedTool == .timing {
                PreviewTimingEditor(
                    frames: $frames,
                    selectedFrameIndex: $selectedFrameIndex,
                    onDeleteFrame: deleteFrame,
                    isDarkMode: true
                )
                .transition(.opacity)
            } else {
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
        .frame(height: 140)
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

        saveProgress()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Data Management
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func loadMovieData() {
        frames = movie.framesData
        storyScript = movie.storyScript
        storySketch = movie.storySketch
        recordedAudio = movie.audioNarration
        totalDuration = frames.reduce(0) { $0 + $1.duration }
    }

    private func saveProgress() {
        movie.framesData = frames
        movie.storyScript = storyScript
        movie.storySketch = storySketch
        if let audio = recordedAudio {
            movie.audioNarration = audio
        }
        try? modelContext.save()
    }

    private func saveScriptToMovie() {
        movie.storyScript = storyScript
        movie.storySketch = storySketch
        try? modelContext.save()
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Camera / Gallery Handlers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func handleCameraFrames(_ newFrames: [FrameData]) {
        guard !newFrames.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            frames = newFrames
        }
        saveProgress()
    }

    private func handleGallerySelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        Task { @MainActor in
            var importedFrames: [FrameData] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    importedFrames.append(FrameData(image: image))
                }
            }

            guard !importedFrames.isEmpty else { return }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                frames.append(contentsOf: importedFrames)
            }
            saveProgress()
            
            // Clear selection for next use
            selectedPhotos = []
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
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
