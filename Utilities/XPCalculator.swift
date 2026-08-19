import Foundation

/// Stateless pure-function calculator for all XP awards in ClassMotion.
/// All methods are static — no instance state needed.
enum XPCalculator {
    
    /// XP awarded for each frame captured in the camera.
    static func pointsForFrameCapture() -> Int { 5 }
    
    /// XP awarded for saving a voice narration.
    /// - Parameter isFirstTime: `true` if this is the first ever narration
    ///   on this movie (audioNarration was nil before), `false` for re-records.
    static func pointsForNarration(isFirstTime: Bool) -> Int {
        isFirstTime ? 20 : 10
    }
    
    /// XP awarded once per movie when the creator customizes 3+ frame durations
    /// away from the default (0.1s).
    static func pointsForCustomTiming() -> Int { 15 }
    
    /// XP awarded when a movie is completed/saved.
    static func pointsForSubmission() -> Int { 25 }
}
