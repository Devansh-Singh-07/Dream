---
name: ClassMotion Project Context
description: Architecture, components, design language, and gamification system for the ClassMotion iPad stop-motion animation app (Swift Student Challenge 2026)
---

# ClassMotion Project Context

## Project Overview
- **Name**: ClassMotion
- **Platform**: Xcode App Playground (.swiftpm package), iPad only
- **Minimum iOS**: 26+
- **Tech Stack**: SwiftUI + SwiftData + AVFoundation

## Design Language
iOS 26 "liquid glass" style:
- `.glassEffect` cards via `glassCard()` / `cardStyle()` modifiers (in `Utilities/DesignSystem.swift`)
- Dark gradient backgrounds via `MeshGradientBackground` / `.glassBackground()`
- Rounded corners: 16pt (`.cornerRadius`) or 12pt (`.cornerRadiusSmall`)
- Spring animations throughout (response 0.3–0.45, damping 0.6–0.8)
- Haptic feedback on interactions (`UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`)
- Design system colors: `.appBlue`, `.appGreen`, `.appOrange`, `.appPurple`, `.appRed`
- Semantic colors: `.studentPrimary` (blue), `.teacherPrimary` (green), `.inProgress`, `.submitted`, `.graded`

## Directory Structure
```
ClassMotion.swiftpm/
├── App/                    # App entry point
├── Models/
│   ├── Model.swift         # Assignment, Project, FrameData, StoryboardData (SwiftData)
│   ├── StudentProfile.swift # Gamification profile (SwiftData) — totalXP, level, badges
│   ├── BadgeDefinition.swift # Static catalog of 10 badges
│   ├── DemoDataManager.swift
│   └── Item.swift
├── Services/
│   ├── CameraManager.swift  # AVFoundation camera session + photo capture
│   ├── AudioRecorder.swift   # Voice narration recording
│   └── VideoExporter.swift   # Export frames → video
├── Utilities/
│   └── DesignSystem.swift    # Colors, fonts, spacing, view modifiers, reusable components
└── Views/
    ├── Camera/
    │   ├── CameraView.swift         # Main stop-motion camera (onion skin, capture button)
    │   ├── CameraPreviewView.swift  # UIViewRepresentable for camera preview layer
    │   └── Components/              # CameraActionButton, CaptureButton, TopBar, etc.
    ├── Preview/                     # Frame preview/playback
    ├── Student/                     # Student flow views (assignments, projects, profile)
    ├── Submission/                  # Audio recording, submission flow
    ├── Teacher/                     # Teacher grading views
    └── Welcome/                     # Welcome/onboarding
```

## Key Data Models (SwiftData)

### Assignment
- `id: UUID`, `title: String`, `instructions: String`, `minFrames: Int`, `totalPoints: Int`
- `projects: [Project]` (cascade delete)

### Project
- `id: UUID`, `assignment: Assignment?`, `framesData: [FrameData]`, `audioNarration: Data?`
- `framesPerSecond: Double`, `status: String` ("in_progress" | "submitted" | "graded")
- Gamification: `pointsAwarded: Int?`, `xpEarned: Int`, `hasAwardedCustomTimingBonus: Bool`
- Computed: `frameCount`, `meetsMinimum`, `hasAudio`

### FrameData (Codable, not SwiftData)
- JPEG image data with caching via `NSCache`
- `duration: Double` (per-frame timing), `storyboardData: StoryboardData?`

### StudentProfile
- `totalXP: Int`, `currentStreak: Int`, `lastActiveDate: Date?`, `earnedBadgeIDs: [String]`
- Computed: `level` (via `calculateLevel(for:)`), `xpProgressToNextLevel`, `xpToNextLevel`
- Level formula: threshold for level N = `N * 100 + (N - 1) * 50`
- `hasBadge(_:)` helper
- Needs `static fetchOrCreate(context:)` — fetches single profile or creates one

## Gamification System

### BadgeDefinition (static catalog, 10 badges)
| ID | Title | SF Symbol | XP Reward | Trigger |
|---|---|---|---|---|
| `first_take` | First Take | `video.fill` | 50 | First ever frame captured |
| `storyteller` | Storyteller | `mic.fill` | 30 | First voice narration |
| `directors_cut` | Director's Cut | `timer` | 40 | Custom timing on 5+ frames |
| `creative_spark` | Creative Spark | `sparkles` | 75 | First assignment submitted |
| `on_a_roll` | On a Roll | `flame.fill` | 60 | Created on 3 different days |
| `perfectionist` | Perfectionist | `arrow.triangle.2.circlepath` | 35 | Re-recorded narration |
| `rising_star` | Rising Star | `star.fill` | 100 | Reached Level 5 |
| `marathon_maker` | Marathon Maker | `film.fill` | 80 | 30+ frames in one project |
| `finisher` | Finisher | `flag.checkered` | 120 | Submitted 5 total projects |
| `teachers_pick` | Teacher's Pick | `trophy.fill` | 150 | Manual teacher award |

### XPCalculator (stateless pure functions — needs to be created)
- `pointsForFrameCapture()` → 5 XP per frame
- `pointsForNarration(isFirstTime:)` → bonus for first narration
- `pointsForCustomTiming(customizedFrameCount:)` → bonus for custom timing
- `pointsForSubmission()` → XP for submitting
- `xpFromGrade(pointsAwarded:)` → XP from teacher grade

### Gamification UI Components (some need to be created)
- **AchievementToast** — reusable toast + `.achievementToast(item:)` view modifier, auto-dismiss 2.5s
- **LevelUpView** — full-screen celebration overlay, takes `newLevel: Int`
- **PlayerCardView** — compact XP/level widget for WelcomeView
- **StudentProfileView** — full badge grid + stats (exists at `Views/Student/StudentProfileView.swift`)

## Critical Design Rule
> **Purely additive positive reinforcement** — NEVER gate, block, or restrict any existing action based on XP, points, or badges. Gamification is reward-only.

## CameraView Capture Flow
The main capture flow in `CameraView.swift`:
1. User taps capture button → `captureFrame()` triggers haptic + calls `cameraManager.capturePhoto()`
2. `CameraManager` publishes captured image via `capturedImage` property
3. `.onChange(of: cameraManager.capturedImage)` calls `handleCapturedImage(_:)`
4. `handleCapturedImage` appends `FrameData` to `capturedFrames`, clears capture, saves progress
5. Every 10th frame triggers `triggerCelebration()` (2-second overlay)

**Gamification integration point**: `handleCapturedImage(_:)` is where XP awards, badge checks, and level-up detection should be wired.
