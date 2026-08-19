import SwiftUI

// MARK: - Celebration Event

/// A single celebration event: either a level-up or a badge/XP toast.
/// Level-ups always take priority and are shown before toasts.
enum CelebrationEvent: Identifiable {
    case levelUp(newLevel: Int)
    case toast(AchievementToastItem)
    
    var id: String {
        switch self {
        case .levelUp(let level): return "levelUp_\(level)"
        case .toast(let item): return item.id.uuidString
        }
    }
    
    /// Sort priority — lower = shown first. Level-ups before toasts.
    var sortOrder: Int {
        switch self {
        case .levelUp: return 0
        case .toast: return 1
        }
    }
}

// MARK: - Celebration Queue

/// Manages an ordered queue of celebration events (level-ups, badge toasts).
/// Shows one event at a time; after each dismisses, the next is presented.
/// Prevents simultaneous overlays from racing.
@MainActor
@Observable
class CelebrationQueue {
    private(set) var pendingEvents: [CelebrationEvent] = []
    private(set) var currentEvent: CelebrationEvent? = nil
    private(set) var isPresenting: Bool = false
    
    /// Enqueues one or more events. Level-ups are sorted to front.
    /// If nothing is currently presenting, starts immediately.
    func enqueue(_ events: [CelebrationEvent]) {
        guard !events.isEmpty else { return }
        pendingEvents.append(contentsOf: events)
        // Re-sort: level-ups first, then toasts in insertion order
        pendingEvents.sort { $0.sortOrder < $1.sortOrder }
        if !isPresenting {
            presentNext()
        }
    }
    
    /// Convenience: enqueue a single event.
    func enqueue(_ event: CelebrationEvent) {
        enqueue([event])
    }
    
    /// Called when the current event finishes its animation/dismiss.
    func currentDismissed() {
        isPresenting = false
        currentEvent = nil
        // Brief gap before next event
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            presentNext()
        }
    }
    
    /// Presents the next event from the queue.
    private func presentNext() {
        guard !pendingEvents.isEmpty else { return }
        let next = pendingEvents.removeFirst()
        currentEvent = next
        isPresenting = true
    }
    
    /// Builds a combined list of events from an XP award result and optional badges.
    /// Convenience for call sites that award XP + badges in one batch.
    static func eventsFrom(
        result: XPAwardResult,
        unlockedBadges: [BadgeDefinition] = [],
        fallbackToast: AchievementToastItem? = nil
    ) -> [CelebrationEvent] {
        var events: [CelebrationEvent] = []
        
        // Level-up event
        if result.didLevelUp {
            events.append(.levelUp(newLevel: result.newLevel))
        }
        
        // Badge toasts
        for badge in unlockedBadges {
            events.append(.toast(AchievementToastItem(
                title: badge.title,
                icon: badge.sfSymbol,
                xpReward: badge.xpReward,
                message: badge.description
            )))
        }
        
        // Fallback toast (e.g. "Nice Timing!" XP-only notification)
        if let fallback = fallbackToast, unlockedBadges.isEmpty {
            events.append(.toast(fallback))
        }
        
        return events
    }
}

// MARK: - Celebration Queue Modifier

/// View modifier that attaches the celebration overlay + toast system.
/// Reads from a `CelebrationQueue` and presents events one at a time.
struct CelebrationQueueModifier: ViewModifier {
    @Bindable var queue: CelebrationQueue
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if let event = queue.currentEvent {
                    switch event {
                    case .levelUp(let newLevel):
                        LevelUpView(newLevel: newLevel) {
                            queue.currentDismissed()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .zIndex(1000)
                        
                    case .toast(let item):
                        // Toast positioned at top, auto-dismisses
                        VStack {
                            AchievementToast(item: item)
                                .padding(.top, 8)
                                .onAppear {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .seconds(2.5))
                                        queue.currentDismissed()
                                    }
                                }
                            Spacer()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                    }
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: queue.currentEvent?.id)
    }
}

extension View {
    /// Attaches the celebration queue overlay system to this view.
    /// Shows level-ups and badge toasts one at a time in priority order.
    func celebrationQueue(_ queue: CelebrationQueue) -> some View {
        modifier(CelebrationQueueModifier(queue: queue))
    }
}
