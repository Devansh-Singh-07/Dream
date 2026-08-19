import SwiftUI
import SwiftData

extension Notification.Name {
    static let dismissToHome = Notification.Name("dismissToHome")
}

struct SaveConfirmationView: View {
    let frames: [FrameData]
    var existingMovie: Movie?
    let audioData: Data?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var hasSaved = false
    
    // MARK: - Gamification Results
    @State private var xpEarnedThisSave: Int = 0
    @State private var newlyUnlockedBadges: [BadgeDefinition] = []
    @State private var showLevelUp: Bool = false
    @State private var newLevelReached: Int = 0
    @State private var profileLevelAfter: Int = 1
    @State private var profileProgressAfter: Double = 0
    @State private var profileTotalXPAfter: Int = 0
    
    // MARK: - Animation Sequencing
    @State private var showSuccessContent: Bool = false
    @State private var showXPCountUp: Bool = false
    @State private var displayedXP: Int = 0
    @State private var showProgressBar: Bool = false
    @State private var revealedBadgeCount: Int = 0
    
    var body: some View {
        ZStack {
            CandyBackground()
            
            if !hasSaved {
                confirmationScreen
            } else {
                successScreen
            }
            
            // Level-up overlay
            if showLevelUp {
                LevelUpView(newLevel: newLevelReached) {
                    showLevelUp = false
                    startCelebrationSequence()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(1000)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            if !hasSaved {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showLevelUp)
    }
    
    // MARK: - Confirmation Screen
    
    private var confirmationScreen: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appYellow, .appOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Ready to Save\nYour Masterpiece?")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("Your stop-motion animation is looking awesome!")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Stats in colorful bubbles
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("\(frames.count)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appBlue)
                        Text("Frames")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(Color.appBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: .cornerRadiusSmall))
                    
                    VStack(spacing: 8) {
                        Text("\(animationDuration, specifier: "%.1f")s")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.appGreen)
                        Text("Duration")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(Color.appGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: .cornerRadiusSmall))
                }
                .padding(.vertical, 16)
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 16) {
                Button(action: saveMovie) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text("Save Movie")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [.appGreen, .appGreen.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .appGreen.opacity(0.35), radius: 15, x: 0, y: 8)
                }
                .buttonStyle(BubbleButtonStyle())
                
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Not Yet, Keep Creating")
                    }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.appBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Success Screen
    
    private var successScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    if showSuccessContent {
                        successHeader
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                            .padding(.top, 24)
                    }
                    
                    if showXPCountUp {
                        xpEarnedCard
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                    
                    if showProgressBar {
                        levelProgressCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if revealedBadgeCount > 0 {
                        badgeRevealSection
                    }
                    
                    if showSuccessContent {
                        movieInfoSection
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 24)
            }
            
            if showSuccessContent {
                navigationButtons
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Success Screen Components
    
    private var successHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appOrange, .appYellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("You Did It!")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient.rainbow
                )
            
            if let movie = existingMovie {
                Text("Your \"\(movie.title)\" animation is saved!")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Text("Your animation is saved and ready to watch!")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    private var xpEarnedCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appYellow)
                Text("XP EARNED")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(2)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("+\(displayedXP)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appOrange, Color.appYellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText())
                    .monospacedDigit()
                
                Text("XP")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.appOrange.opacity(0.7))
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: .cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: .cornerRadius)
                .stroke(Color.appYellow.opacity(0.3), lineWidth: 2)
        }
        .shadow(color: .appYellow.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
    
    private var levelProgressCard: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appYellow)
                    Text("Level \(profileLevelAfter)")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                }
                
                Spacer()
                
                Text("\(profileTotalXPAfter) XP total")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 14)
                    
                    Capsule()
                        .fill(LinearGradient.rainbow)
                        .frame(
                            width: max(0, geo.size.width * profileProgressAfter),
                            height: 14
                        )
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.7).delay(0.2),
                            value: profileProgressAfter
                        )
                }
            }
            .frame(height: 14)
        }
        .padding(20)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: .cornerRadiusSmall))
        .shadow(color: .appBlue.opacity(0.08), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
    
    private var badgeRevealSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appYellow)
                Text("BADGES UNLOCKED")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(
                Array(newlyUnlockedBadges.prefix(revealedBadgeCount).enumerated()),
                id: \.element.id
            ) { _, badge in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appOrange, Color.appYellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: badge.sfSymbol)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color.appOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(badge.title)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        
                        Text(badge.description)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("+\(badge.xpReward) XP")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color.appGreen)
                        )
                }
                .padding(16)
                .background(Color.bgCard, in: RoundedRectangle(cornerRadius: .cornerRadiusSmall))
                .shadow(color: .appOrange.opacity(0.08), radius: 8, x: 0, y: 4)
                .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var movieInfoSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 24)
            
            Text("Come back anytime to watch or edit your movie!")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            HStack(spacing: 40) {
                Label("\(frames.count) frames", systemImage: "camera.fill")
                    .font(.system(.subheadline, design: .rounded))
                Label("\(animationDuration, specifier: "%.1f")s long", systemImage: "clock.fill")
                    .font(.system(.subheadline, design: .rounded))
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }
    
    private var navigationButtons: some View {
        VStack(spacing: 14) {
            Button {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    NotificationCenter.default.post(name: .dismissToHome, object: nil)
                }
            } label: {
                Label("Back to Studio", systemImage: "house.fill")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.appBlue, in: Capsule())
                    .shadow(color: .appBlue.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(BubbleButtonStyle())
            
            NavigationLink(destination: StudentProfileView()) {
                Label("View My Progress", systemImage: "star.fill")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.appBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appBlue.opacity(0.1), in: Capsule())
            }
            .buttonStyle(BubbleButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
    }
    
    // MARK: - Helpers
    
    private var animationDuration: Double {
        frames.reduce(0) { $0 + $1.duration }
    }
    
    // MARK: - Save Movie + Gamification
    
    private func saveMovie() {
        let movie: Movie
        if let existing = existingMovie {
            existing.framesData = frames
            existing.audioNarration = audioData
            movie = existing
        } else {
            let newMovie = Movie()
            newMovie.framesData = frames
            newMovie.audioNarration = audioData
            modelContext.insert(newMovie)
            movie = newMovie
        }
        
        let profile = StudentProfile.fetchOrCreate(context: modelContext)
        let levelBefore = profile.level
        var totalXPAwarded = 0
        var unlockedBadges: [BadgeDefinition] = []
        
        let completionResult = profile.awardXP(XPCalculator.pointsForSubmission())
        totalXPAwarded += completionResult.xpAwarded
        
        updateStreak(profile: profile)
        
        let movieDescriptor = FetchDescriptor<Movie>()
        let movieCount = (try? modelContext.fetch(movieDescriptor).count) ?? 1
        
        if movieCount == 1, let result = profile.awardBadge("creative_spark") {
            totalXPAwarded += result.xpAwarded
            unlockedBadges.append(.creativeSpark)
        }
        
        if frames.count >= 30, let result = profile.awardBadge("marathon_maker") {
            totalXPAwarded += result.xpAwarded
            unlockedBadges.append(.marathonMaker)
        }
        
        if movieCount >= 5, let result = profile.awardBadge("finisher") {
            totalXPAwarded += result.xpAwarded
            unlockedBadges.append(.finisher)
        }
        
        if profile.currentStreak >= 3, let result = profile.awardBadge("on_a_roll") {
            totalXPAwarded += result.xpAwarded
            unlockedBadges.append(.onARoll)
        }
        
        movie.xpEarned = totalXPAwarded
        
        try? modelContext.save()
        
        let levelAfter = profile.level
        xpEarnedThisSave = totalXPAwarded
        newlyUnlockedBadges = unlockedBadges
        profileLevelAfter = levelAfter
        profileProgressAfter = profile.xpProgressToNextLevel
        profileTotalXPAfter = profile.totalXP
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasSaved = true
        }
        
        if levelAfter > levelBefore {
            newLevelReached = levelAfter
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showLevelUp = true
                }
            }
        } else {
            startCelebrationSequence()
        }
    }
    
    private func updateStreak(profile: StudentProfile) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastActive = profile.lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastActive)
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                profile.currentStreak += 1
            } else if daysBetween == 0 {
                // Same day
            } else {
                profile.currentStreak = 1
            }
        } else {
            profile.currentStreak = 1
        }
        profile.lastActiveDate = today
    }
    
    private func startCelebrationSequence() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccessContent = true
            }
            
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showXPCountUp = true
            }
            
            let steps = 20
            let total = xpEarnedThisSave
            if total > 0 {
                for i in 1...steps {
                    try? await Task.sleep(for: .milliseconds(50))
                    withAnimation(.easeOut(duration: 0.05)) {
                        displayedXP = Int(Double(total) * Double(i) / Double(steps))
                    }
                }
            }
            
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showProgressBar = true
            }
            
            for i in 0..<newlyUnlockedBadges.count {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    revealedBadgeCount = i + 1
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let frames = (1...20).map { _ in
        FrameData(image: UIImage(systemName: "photo")!)
    }
    
    return NavigationStack {
        SaveConfirmationView(frames: frames, existingMovie: nil, audioData: nil)
            .modelContainer(for: [Movie.self, StudentProfile.self])
    }
}
