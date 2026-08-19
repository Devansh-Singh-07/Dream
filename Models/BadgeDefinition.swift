import Foundation

struct BadgeDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let sfSymbol: String
    let description: String
    let xpReward: Int
    
    static let allBadges: [BadgeDefinition] = [
        .firstTake,
        .storyteller,
        .directorsCut,
        .creativeSpark,
        .onARoll,
        .perfectionist,
        .risingStar,
        .marathonMaker,
        .finisher
    ]
    
    // MARK: - Badge Definitions
    
    static let firstTake = BadgeDefinition(
        id: "first_take",
        title: "First Take",
        sfSymbol: "video.fill",
        description: "Created your first movie",
        xpReward: 50
    )
    
    static let storyteller = BadgeDefinition(
        id: "storyteller",
        title: "Storyteller",
        sfSymbol: "mic.fill",
        description: "Added voice narration for the first time",
        xpReward: 30
    )
    
    static let directorsCut = BadgeDefinition(
        id: "directors_cut",
        title: "Director's Cut",
        sfSymbol: "timer",
        description: "Customized timing on 5+ frames in one movie",
        xpReward: 40
    )
    
    static let creativeSpark = BadgeDefinition(
        id: "creative_spark",
        title: "Creative Spark",
        sfSymbol: "sparkles",
        description: "Completed your first movie",
        xpReward: 75
    )
    
    static let onARoll = BadgeDefinition(
        id: "on_a_roll",
        title: "On a Roll",
        sfSymbol: "flame.fill",
        description: "Created on 3 different days",
        xpReward: 60
    )
    
    static let perfectionist = BadgeDefinition(
        id: "perfectionist",
        title: "Perfectionist",
        sfSymbol: "arrow.triangle.2.circlepath",
        description: "Re-recorded narration to make it just right",
        xpReward: 35
    )
    
    static let risingStar = BadgeDefinition(
        id: "rising_star",
        title: "Rising Star",
        sfSymbol: "star.fill",
        description: "Reached Level 5",
        xpReward: 100
    )
    
    static let marathonMaker = BadgeDefinition(
        id: "marathon_maker",
        title: "Marathon Maker",
        sfSymbol: "film.fill",
        description: "Captured 30+ frames in one movie",
        xpReward: 80
    )
    
    static let finisher = BadgeDefinition(
        id: "finisher",
        title: "Finisher",
        sfSymbol: "flag.checkered",
        description: "Completed 5 total movies",
        xpReward: 120
    )
}

