import SwiftUI
import SwiftData

struct CameraView: View {
    var existingMovie: Movie? = nil
    var initialFrames: [FrameData] = []
    var onFramesCaptured: (([FrameData]) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var cameraManager = CameraManager()
    @State private var capturedFrames: [FrameData] = []
    @State private var onionOpacity: Double = 0.5
    @State private var captureButtonScale: CGFloat = 1.0
    @State private var showingCelebration = false
    
    // Story Canvas
    @State private var showingScriptPanel = false
    @State private var storyScript: String = ""
    @State private var storySketch: Data? = nil
    
    @State private var activeMovie: Movie? = nil

    /// Whether this CameraView is managed by a MovieEditorView (callback mode)
    private var isCallbackMode: Bool { onFramesCaptured != nil }

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color(.systemBackground))
                .ignoresSafeArea()

            #if targetEnvironment(simulator)
            ZStack {
                (colorScheme == .dark ? Color.black : Color(.black)).ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                    
                    Text("Camera Preview")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text("Simulator Mode")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.gray)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                        Text("Live camera works on physical iPad, Check demo Video for more info.")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassCapsule()
                }.padding(16)
                .glassEffect(cornerRadius: 34)
                .colorScheme(.dark)
            }
            #else
            if let previewLayer = cameraManager.previewLayer {
                CameraPreviewView(previewLayer: previewLayer).ignoresSafeArea()
            }
            #endif

            if let lastFrame = capturedFrames.last?.image {
                GeometryReader { geo in
                    Image(uiImage: lastFrame)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .opacity(onionOpacity)
                        .allowsHitTesting(false)
                }
                .ignoresSafeArea()
            }

            if showingCelebration {
                CelebrationView(frameCount: capturedFrames.count).ignoresSafeArea().transition(.opacity)
            }

            VStack(spacing: 0) {
                CameraTopBar(
                    capturedFrames: capturedFrames,
                    hasScript: !storyScript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    isScriptVisible: showingScriptPanel,
                    onDismiss: dismissAndSave,
                    onScript: {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                            showingScriptPanel.toggle()
                        }
                    }
                )
                Spacer()
                VStack(spacing: 20) {
                    OnionSkinCard(opacity: $onionOpacity)
                    CameraActionButtons(
                        capturedCount: capturedFrames.count,
                        captureScale: captureButtonScale,
                        onCapture: captureFrame,
                        onUndo: deleteLastFrame,
                        onDone: dismissAndSave
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }

        }
        .onAppear {
            loadExistingFrames()
            cameraManager.checkPermission()
        }
        .onDisappear { cameraManager.stop() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                saveProgress()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissToHome)) { _ in
            dismiss()
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if let image = newImage { handleCapturedImage(image) }
        }
        .sheet(isPresented: $showingScriptPanel, onDismiss: saveProgress) {
            StoryScriptPanel(script: $storyScript, sketchData: $storySketch)
        }
    }

    // MARK: - Persistence
    private func dismissAndSave() {
        if isCallbackMode {
            // Return frames directly to the MovieEditorView
            onFramesCaptured?(capturedFrames)
            dismiss()
        } else {
            // Standalone behavior
            saveProgress()
            dismiss()
        }
    }
    
    private func saveProgress() {
        // In callback mode, the editor handles persistence
        guard !isCallbackMode else { return }
        
        if capturedFrames.isEmpty {
            if let movie = activeMovie {
                modelContext.delete(movie)
                activeMovie = nil
                try? modelContext.save()
            }
            return
        }
        
        if let movie = activeMovie ?? existingMovie {
            movie.framesData = capturedFrames
            movie.storyScript = storyScript
            movie.storySketch = storySketch
            activeMovie = movie
        } else {
            let movie = Movie()
            movie.framesData = capturedFrames
            movie.storyScript = storyScript
            movie.storySketch = storySketch
            modelContext.insert(movie)
            activeMovie = movie
        }
        try? modelContext.save()
    }

    // MARK: - Actions
    private func captureFrame() {
        captureButtonScale = 0.85
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            captureButtonScale = 1.0
        }
        cameraManager.capturePhoto()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Visual feedback pulse
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            captureButtonScale = 0.85
        }
    }

    private func handleCapturedImage(_ image: UIImage) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { 
            capturedFrames.append(FrameData(image: image))
        }
        cameraManager.capturedImage = nil
        
        if !isCallbackMode {
            saveProgress()
        }
        
        // Success haptic
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        
        if capturedFrames.count > 0 && capturedFrames.count % 10 == 0 { 
            triggerCelebration() 
        }
    }

    private func deleteLastFrame() {
        guard !capturedFrames.isEmpty else { return }
        
        // Haptic before animation
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { 
            capturedFrames.removeLast()
        }
        
        if !isCallbackMode {
            saveProgress()
        }
    }

    private func loadExistingFrames() {
        if !initialFrames.isEmpty && capturedFrames.isEmpty {
            // In callback mode, use the frames passed from the editor
            capturedFrames = initialFrames
            storyScript = existingMovie?.storyScript ?? ""
            storySketch = existingMovie?.storySketch
            activeMovie = existingMovie
        } else if let existing = existingMovie, capturedFrames.isEmpty {
            // Legacy standalone mode
            capturedFrames = existing.framesData
            storyScript = existing.storyScript
            storySketch = existing.storySketch
            activeMovie = existing
        }
    }

    private func triggerCelebration() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { 
            showingCelebration = true 
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { 
                showingCelebration = false 
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) { 
            captureButtonScale = 1.1 
        }
    }
    
}
