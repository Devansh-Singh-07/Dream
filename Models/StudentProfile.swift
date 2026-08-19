import SwiftUI
import SwiftData
import Foundation

@Model
@objcMembers
class StudentProfile {
    var id: UUID
    var totalXP: Int
    var currentStreak: Int
    var lastActiveDate: Date?
    var earnedBadgeIDs: [String]
    
    // Tracking for "perfectionist" badge (first re-record)
    var hasRerecordedNarration: Bool = false
    
    init() {
        self.id = UUID()
        self.totalXP = 0
        self.currentStreak = 0
        self.lastActiveDate = nil
        self.earnedBadgeIDs = []
        self.hasRerecordedNarration = false
    }
    
    // MARK: - Computed Properties
    
    var level: Int {
        StudentProfile.calculateLevel(for: totalXP)
    }
    
    var xpProgressToNextLevel: Double {
        let currentLevel = level
        let currentThreshold = StudentProfile.xpThreshold(for: currentLevel)
        let nextThreshold = StudentProfile.xpThreshold(for: currentLevel + 1)
        let progress = Double(totalXP - currentThreshold) / Double(nextThreshold - currentThreshold)
        return min(max(progress, 0.0), 1.0)
    }
    
    var xpToNextLevel: Int {
        let currentLevel = level
        let nextThreshold = StudentProfile.xpThreshold(for: currentLevel + 1)
        return nextThreshold - totalXP
    }
    
    // MARK: - Level Calculation
    
    static func calculateLevel(for xp: Int) -> Int {
        var level = 1
        while xp >= xpThreshold(for: level + 1) {
            level += 1
        }
        return level
    }
    
    static func xpThreshold(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        // Level N requires: N * 100 + (N - 1) * 50
        return level * 100 + (level - 1) * 50
    }
    
    // MARK: - Fetch or Create
    
    /// Returns the singleton StudentProfile, creating one if none exists.
    /// Safe to call from multiple views — ModelContext is @MainActor-isolated,
    /// so all calls serialize on the main thread. No duplicate risk.
    static func fetchOrCreate(context: ModelContext) -> StudentProfile {
        let descriptor = FetchDescriptor<StudentProfile>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let profile = StudentProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }
    
    // MARK: - Badge Helpers
    
    func hasBadge(_ badgeID: String) -> Bool {
        earnedBadgeIDs.contains(badgeID)
    }
    
    // MARK: - XP Award Helper
    
    /// Captures level before, applies XP, captures level after.
    /// Returns an `XPAwardResult` indicating whether a level-up occurred.
    @discardableResult
    func awardXP(_ amount: Int) -> XPAwardResult {
        let levelBefore = level
        totalXP += amount
        let levelAfter = level
        return XPAwardResult(
            xpAwarded: amount,
            levelBefore: levelBefore,
            levelAfter: levelAfter
        )
    }
    
    /// Awards a badge if not already earned. Returns the badge definition
    /// if it was newly awarded (nil if already owned).
    /// Also awards the badge's XP reward and rolls it into the result.
    @discardableResult
    func awardBadge(_ badgeID: String) -> XPAwardResult? {
        guard !hasBadge(badgeID) else { return nil }
        guard let badge = BadgeDefinition.allBadges.first(where: { $0.id == badgeID }) else { return nil }
        earnedBadgeIDs.append(badgeID)
        return awardXP(badge.xpReward)
    }
}

// MARK: - XP Award Result

/// Value type returned by `StudentProfile.awardXP(_:)`.
/// Captures whether the XP award caused a level-up.
struct XPAwardResult {
    let xpAwarded: Int
    let levelBefore: Int
    let levelAfter: Int
    
    var didLevelUp: Bool { levelAfter > levelBefore }
    var newLevel: Int { levelAfter }
    
    /// Merges two results to get the overall before→after picture.
    /// Use when multiple XP awards happen in sequence.
    func merged(with other: XPAwardResult) -> XPAwardResult {
        XPAwardResult(
            xpAwarded: xpAwarded + other.xpAwarded,
            levelBefore: levelBefore,
            levelAfter: other.levelAfter
        )
    }
}
