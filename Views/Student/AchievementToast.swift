import SwiftUI

/// Data model for achievement toast notifications.
struct AchievementToastItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let xpReward: Int
    let message: String
    
    static func == (lhs: AchievementToastItem, rhs: AchievementToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// A toast notification that slides in from the top to celebrate
/// badge unlocks and XP awards. Auto-dismisses after 2.5 seconds.
struct AchievementToast: View {
    let item: AchievementToastItem
    
    var body: some View {
        HStack(spacing: 14) {
            // Badge icon — candy colored
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
                
                Image(systemName: item.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .shadow(color: .appOrange.opacity(0.3), radius: 6, x: 0, y: 3)
            
            // Text content
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(item.message)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // XP reward pill — golden
            Text("+\(item.xpReward) XP")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appGreen, Color.appGreen.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.bgCard, in: RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous))
        .overlay {
            // Rainbow left accent
            HStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: .cornerRadius,
                    bottomLeadingRadius: .cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(LinearGradient.rainbow)
                .frame(width: 5)
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous))
        .shadow(color: .appOrange.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
}

// MARK: - View Modifier

/// Presents an AchievementToast from the top of the screen.
/// Automatically dismisses after 2.5 seconds.
struct AchievementToastModifier: ViewModifier {
    @Binding var item: AchievementToastItem?
    
    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toastItem = item {
                AchievementToast(item: toastItem)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .onAppear {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(2.5))
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                item = nil
                            }
                        }
                    }
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: item != nil)
    }
}

extension View {
    /// Shows an achievement toast notification at the top of the view.
    func achievementToast(item: Binding<AchievementToastItem?>) -> some View {
        modifier(AchievementToastModifier(item: item))
    }
}
