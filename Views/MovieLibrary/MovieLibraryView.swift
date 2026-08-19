import SwiftUI
import SwiftData

struct MovieLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Movie.createdAt, order: .reverse) private var movies: [Movie]
    @Query private var profiles: [StudentProfile]
    
    @State private var showingNewMoviePrompt = false
    @State private var newMovieTitle = ""
    @State private var selectedMovie: Movie?
    @State private var movieToDelete: Movie? = nil
    @State private var showingDeleteConfirmation = false
    @State private var currentTipIndex = Int.random(in: 0...3)
    
    private var profile: StudentProfile {
        profiles.first ?? StudentProfile()
    }
    
    private func ensureProfile() {
        if profiles.isEmpty {
            _ = StudentProfile.fetchOrCreate(context: modelContext)
        }
    }
    
    private let studioTips: [(icon: String, text: String)] = [
        ("lightbulb.fill", "Studio Tip: Move your character just a tiny bit between frames for smooth motion!"),
        ("mic.fill", "Voiceover Tip: Try funny voice effects to bring your figures to life!"),
        ("eye.fill", "Ghost Mode: Use Onion Skin opacity to align your next frame perfectly!"),
        ("bolt.fill", "Speed Trick: Set frame timing to 0.1s for fast action or 0.5s for slow-motion!")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                CandyBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                                            
                        // Player progress card
//                        NavigationLink(destination: StudentProfileView()) {
//                            PlayerCardWidget(profile: profile)
//                        }
//                        .buttonStyle(BubbleButtonStyle())
//                        .padding(.horizontal, 24)
                        
                        // Interactive Studio Tip Banner
                        creativeTipBanner
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                        
                        // Movies Grid or Empty State
                        if movies.isEmpty {
                            emptyStateView
                        } else {
                            moviesGrid
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("My Studio")
            .navigationSubtitle("What story will we bring to life today?")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        hapticFeedback(.medium)
                        showingNewMoviePrompt = true
                    }) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.appBlue)
                        }
                    .buttonStyle(BubbleButtonStyle())
                }
            }
            
            .alert("Name Your Scene", isPresented: $showingNewMoviePrompt) {
                TextField("Movie Title (e.g. Clay Adventure)", text: $newMovieTitle)
                Button("Let's Create!", action: createNewMovie)
                Button("Cancel", role: .cancel) { newMovieTitle = "" }
            } message: {
                Text("Give your stop-motion animation a title!")
            }
            .alert("Delete Scene?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let movie = movieToDelete {
                        deleteMovie(movie)
                    }
                }
                Button("Cancel", role: .cancel) { movieToDelete = nil }
            } message: {
                Text("Are you sure you want to delete this scene? This action cannot be undone.")
            }
            .fullScreenCover(item: $selectedMovie) { movie in
                NavigationStack {
                    MovieEditorView(movie: movie)
                }
            }
            .onAppear {
                ensureProfile()
            }
        }
    }
    
    
    // MARK: - Creative Tip Banner
    private var creativeTipBanner: some View {
        let tip = studioTips[currentTipIndex % studioTips.count]
        
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appBlue.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: tip.icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appBlue)
            }
            
            Text(tip.text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: {
                hapticFeedback(.light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    currentTipIndex = (currentTipIndex + 1) % studioTips.count
                }
            }) {
                Image(systemName: "shuffle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appBlue)
                    .padding(8)
                    .background(Color.appBlue.opacity(0.12), in: Circle())
            }
            .buttonStyle(BubbleButtonStyle())
        }
        .padding(12)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .stroke(Color.appBlue.opacity(0.2), lineWidth: 1.5)
        }
        .shadow(color: Color.appBlue.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.appBlue.opacity(0.12))
                    .frame(width: 130, height: 130)
                
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 58))
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
                Text("Your Studio is Ready")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                
                Text("Tap New Scene to capture your first stop-motion animation!")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    // MARK: - Movies Grid
    private var moviesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Your Projects", systemImage: "film")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                
//                Spacer()
//                
//                Text("\(movies.count) scene\(movies.count == 1 ? "" : "s")")
//                    .font(.system(.caption, design: .rounded, weight: .bold))
//                    .foregroundStyle(Color.appBlue)
//                    .padding(.horizontal, 10)
//                    .padding(.vertical, 4)
//                    .background(Color.appBlue.opacity(0.1), in: Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 6)
            
            // Uniform 2-column grid layout with equal height/size frames
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 18) {
                ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                    MovieCard(movie: movie, accentColor: Color.candyAccent(for: index))
                        .onTapGesture {
                            hapticFeedback(.light)
                            selectedMovie = movie
                        }
                        .contextMenu {
                            Button {
                                hapticFeedback(.light)
                                selectedMovie = movie
                            } label: {
                                Label("Open Scene", systemImage: "pencil.and.outline")
                            }
                            
                            Button(role: .destructive) {
                                movieToDelete = movie
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Scene", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Actions
    private func createNewMovie() {
        let title = newMovieTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Scene" : newMovieTitle
        let movie = Movie(title: title)
        modelContext.insert(movie)
        try? modelContext.save()
        newMovieTitle = ""
        selectedMovie = movie
    }
    
    private func deleteMovie(_ movie: Movie) {
        hapticFeedback(.medium)
        modelContext.delete(movie)
        try? modelContext.save()
        movieToDelete = nil
    }
}

// MARK: - Uniform Refined Movie Card
struct MovieCard: View {
    let movie: Movie
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── 16:9 Standardized Video Frame Thumbnail ──
            ZStack(alignment: .bottomLeading) {
                ZStack(alignment: .topTrailing) {
                    if let firstFrame = movie.framesData.first?.image {
                        Image(uiImage: firstFrame)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.15), Color.bgCanvas],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(16/9, contentMode: .fill)
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundStyle(accentColor.opacity(0.6))
                                    Text("Tap to Shoot")
                                        .font(.system(.caption2, design: .rounded, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                    
                    // Script & Audio Badges (Top Right Overlay)
                    HStack(spacing: 4) {
                        if !movie.storyScript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || movie.storySketch != nil {
                            Image(systemName: "note.text")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Color.appBlue, in: Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        if movie.hasAudio {
                            Image(systemName: "waveform")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Color.appGreen, in: Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(8)
                }
                
                // Duration & Frame Count Badge (Bottom Left Overlay)
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("\(movie.frameCount)f")
                        .monospacedDigit()
                    Text("•")
                        .font(.system(size: 8))
                    Text(String(format: "%.1fs", movie.duration))
                        .monospacedDigit()
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.65), in: Capsule())
                .padding(8)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: .cornerRadiusSmall,
                    topTrailingRadius: .cornerRadiusSmall
                )
            )
            
            // ── Uniform Metadata Footer Box (Fixed Height for Equal Card Sizes) ──
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(movie.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if movie.xpEarned > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("+\(movie.xpEarned) XP")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color.appBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.appBlue.opacity(0.12), in: Capsule())
                    }
                }
            }
            .padding(12)
            .frame(height: 64) // Equal metadata footer height ensures all cards match size exactly
        }
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
        }
        .shadow(color: accentColor.opacity(0.14), radius: 10, x: 0, y: 5)
        .cardPressAnimation()
    }
}

// MARK: - Player Card Widget
struct PlayerCardWidget: View {
    let profile: StudentProfile
    
    var body: some View {
        HStack(spacing: 16) {
            // Level Ring Progress Widget
            ZStack {
                Circle()
                    .stroke(Color.appBlue.opacity(0.12), lineWidth: 6)
                    .frame(width: 64, height: 64)
                
                Circle()
                    .trim(from: 0, to: max(0.05, profile.xpProgressToNextLevel))
                    .stroke(
                        AngularGradient(
                            colors: [.appBlue, .appPink, .appOrange, .appYellow, .appGreen, .appBlue],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: profile.xpProgressToNextLevel)
                
                VStack(spacing: 0) {
                    Text("Lv")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("\(profile.level)")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("Studio Profile")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.appBlue)
                }
                
                HStack(spacing: 12) {
                    Label("\(profile.totalXP) XP", systemImage: "star.fill")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.appBlue)
                    
                    if profile.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.appOrange)
                            Text("\(profile.currentStreak) day streak")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.appOrange)
                        }
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.appBlue)
        }
        .padding(16)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .stroke(Color.appBlue.opacity(0.18), lineWidth: 1.5)
        }
        .shadow(color: Color.appBlue.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Preview
#Preview {
    MovieLibraryView()
        .modelContainer(for: [Movie.self, StudentProfile.self])
}
