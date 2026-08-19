import SwiftUI
import SwiftData

// MARK: - Movie Model
@Model
@objcMembers
class Movie {
    var id: UUID
    var title: String
    var framesData: [FrameData]
    var audioNarration: Data?
    var framesPerSecond: Double = 10.0
    var isDemo: Bool = false
    var createdAt: Date
    
    // Gamification fields
    var xpEarned: Int = 0
    
    // Story planning / script notes
    var storyScript: String = ""
    
    // Story planning / freehand sketch (PencilKit drawing data)
    var storySketch: Data? = nil
    
    init(title: String = "My Movie") {
        self.id = UUID()
        self.title = title
        self.framesData = []
        self.createdAt = Date()
        self.xpEarned = 0
        self.storyScript = ""
    }
    
    var frameCount: Int {
        framesData.count
    }
    
    var hasAudio: Bool {
        audioNarration != nil
    }
    
    var duration: Double {
        framesData.reduce(0) { $0 + $1.duration }
    }
}

// MARK: - Thread-Safe Image Cache (NSCache is thread-safe in Foundation)
final class FrameImageCache: @unchecked Sendable {
    static let shared = FrameImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 200 // up to 200 decoded frames in memory
    }
    
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

// MARK: - FrameData
struct FrameData: Codable, Identifiable, Equatable {
    var id: UUID
    var imageData: Data
    var timestamp: Date
    var duration: Double = 0.1
    var storyboardData: StoryboardData?
    
    init(image: UIImage, duration: Double = 0.1) {
        self.id = UUID()
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
        self.timestamp = Date()
        self.duration = duration
        self.storyboardData = nil
    }
    
    var image: UIImage? {
        let key = id.uuidString
        if let cached = FrameImageCache.shared.image(forKey: key) { return cached }
        guard let decoded = UIImage(data: imageData) else { return nil }
        FrameImageCache.shared.setImage(decoded, forKey: key)
        return decoded
    }
}

// MARK: - Storyboard Data
struct StoryboardData: Codable, Equatable {
    var beginningImageData: Data?
    var middleImageData: Data?
    var endImageData: Data?
    
    var hasBeginning: Bool { beginningImageData != nil }
    var hasMiddle: Bool { middleImageData != nil }
    var hasEnd: Bool { endImageData != nil }
    var isComplete: Bool { hasBeginning && hasMiddle && hasEnd }
}
