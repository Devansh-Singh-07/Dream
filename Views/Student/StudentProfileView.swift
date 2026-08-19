import SwiftUI
import SwiftData

struct StudentProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [StudentProfile]
    @Query private var movies: [Movie]
    
    @State private var selectedBadgeInfo: (badge: BadgeDefinition, isEarned: Bool)? = nil
    
    private var profile: StudentProfile {
        profiles.first ?? StudentProfile()
    }
    
    private func ensureProfile() {
        if profiles.isEmpty {
            _ = StudentProfile.fetchOrCreate(context: modelContext)
        }
    }
    
    private var totalMoviesCreated: Int { movies.count }
    private var totalFramesCaptured: Int { movies.reduce(0) { $0 + $1.frameCount } }
    private var totalXPEarned: Int { movies.reduce(0) { $0 + $1.xpEarned } }
    
    var body: some View {
        ZStack {
            CandyBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // MARK: - Level Ring Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                 .fill(Color.appBlue.opacity(0.1))
                                 .frame(width: 220, height: 220)
                            
                            Circle()
                                 .trim(from: 0, to: profile.xpProgressToNextLevel)
                                 .stroke(
                                     AngularGradient(
                                         colors: [.appBlue, .appPink, .appOrange, .appYellow, .appGreen, .appBlue],
                                         center: .center
                                     ),
                                     style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                 )
                                 .frame(width: 220, height: 220)
                                 .rotationEffect(.degrees(-90))
                                 .animation(.spring(response: 0.6, dampingFraction: 0.7), value: profile.xpProgressToNextLevel)
                            
                            VStack(spacing: 4) {
                                Text("Level")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                
                                Text("\(profile.level)")
                                    .font(.system(size: 68, weight: .heavy, design: .rounded))
                                    .foregroundStyle(LinearGradient.rainbowDiagonal)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.appYellow)
                                    Text("\(profile.totalXP) XP")
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.appBlue)
                            Text("\(profile.xpToNextLevel) XP to Level \(profile.level + 1)")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.appBlue.opacity(0.1), in: Capsule())
                    }
                    .padding(.top, 24)
                    
                    // MARK: - Streak Section
                    if profile.currentStreak > 0 {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.appOrange.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Color.appOrange)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(profile.currentStreak) Day Streak")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                Text("Keep creating to stay on fire!")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: .cornerRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: .cornerRadius)
                                .stroke(Color.appOrange.opacity(0.35), lineWidth: 2)
                        }
                        .shadow(color: .appOrange.opacity(0.12), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 24)
                    }
                    
                    // MARK: - Quick Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Your Studio Stats", systemImage: "chart.bar.fill")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        HStack(spacing: 12) {
                            StatCard(
                                icon: "film.fill",
                                value: "\(totalMoviesCreated)",
                                label: "Movies\nCreated",
                                color: .appBlue
                            )
                            
                            StatCard(
                                icon: "photo.stack.fill",
                                value: "\(totalFramesCaptured)",
                                label: "Total\nFrames",
                                color: .appBlue
                            )
                            
                            StatCard(
                                icon: "star.fill",
                                value: "\(totalXPEarned)",
                                label: "Movie\nXP",
                                color: .appOrange
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // MARK: - Badge Collection
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Badge Collection", systemImage: "trophy.fill")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                            Spacer()
                            Text("\(profile.earnedBadgeIDs.count)/\(BadgeDefinition.allBadges.count) Unlocked")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.appOrange)
                        }
                        .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ], spacing: 14) {
                            ForEach(BadgeDefinition.allBadges) { badge in
                                let isEarned = profile.hasBadge(badge.id)
                                BadgeCard(
                                    badge: badge,
                                    isEarned: isEarned
                                )
                                .onTapGesture {
                                    hapticFeedback(.light)
                                    selectedBadgeInfo = (badge, isEarned)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer().frame(height: 32)
                }
            }
        }
        .navigationTitle("Your Progress")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            selectedBadgeInfo?.isEarned == true ? "Badge Unlocked" : "Locked Badge",
            isPresented: Binding(
                get: { selectedBadgeInfo != nil },
                set: { if !$0 { selectedBadgeInfo = nil } }
            )
        ) {
            Button("Awesome", role: .cancel) { selectedBadgeInfo = nil }
        } message: {
            if let info = selectedBadgeInfo {
                Text("\(info.badge.title)\n\n\(info.badge.description)\n\(info.isEarned ? "Awarded +\(info.badge.xpReward) XP!" : "Earn +\(info.badge.xpReward) XP when unlocked!")")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.appBlue)
                }
            }
        }
        .onAppear {
            ensureProfile()
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .appBlue
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: .cornerRadiusSmall))
        .shadow(color: color.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Badge Card
struct BadgeCard: View {
    let badge: BadgeDefinition
    let isEarned: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if isEarned {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appOrange, Color.appYellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: .appOrange.opacity(0.35), radius: 8, x: 0, y: 4)
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 58, height: 58)
                }
                
                Image(systemName: isEarned ? badge.sfSymbol : "lock.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isEarned ? .white : .gray)
            }
            
            VStack(spacing: 4) {
                Text(badge.title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(isEarned ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if isEarned {
                    Text("+\(badge.xpReward) XP")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.appOrange)
                } else {
                    Text("Tap for info")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                .fill(isEarned ? Color.appOrange.opacity(0.08) : Color(.systemGray6))
        )
        .overlay {
            if isEarned {
                RoundedRectangle(cornerRadius: .cornerRadiusSmall, style: .continuous)
                    .stroke(Color.appOrange.opacity(0.3), lineWidth: 2)
            }
        }
        .cardPressAnimation()
    }
}

#Preview {
    NavigationStack {
        StudentProfileView()
            .modelContainer(for: [StudentProfile.self, Movie.self])
    }
}
