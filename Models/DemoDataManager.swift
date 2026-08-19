import SwiftUI
import SwiftData
import UIKit

@MainActor
struct DemoDataManager {
    
    static func loadDemoDataIfNeeded(context: ModelContext) {
        // Only run movie seeding if no movies exist
        let count = (try? context.fetchCount(FetchDescriptor<Movie>())) ?? 0
        guard count == 0 else { return }
        
        // Generate 15 demo frames
        let colors: [UIColor] = [
            .systemRed, .systemOrange, .systemYellow, .systemGreen,
            .systemMint, .systemTeal, .systemCyan, .systemBlue,
            .systemIndigo, .systemPurple, .systemPink, .systemBrown,
            .systemRed, .systemOrange, .systemYellow
        ]
        
        var frames: [FrameData] = []
        for i in 1...15 {
            let image = makeFrame(number: i, color: colors[i - 1])
            frames.append(FrameData(image: image, duration: 0.1))
        }
        
        let movie = Movie(title: "Demo Movie")
        movie.framesData = frames
        movie.isDemo = true
        context.insert(movie)
        try? context.save()
    }
    
    private static func makeFrame(number: Int, color: UIColor) -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { ctx in
            // Background
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Border
            let inset = CGRect(origin: .zero, size: size).insetBy(dx: 16, dy: 16)
            let path = UIBezierPath(roundedRect: inset, cornerRadius: 24)
            path.lineWidth = 4
            UIColor.white.withAlphaComponent(0.35).setStroke()
            path.stroke()
            
            // Frame text
            let text = "Frame \(number)"
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 52, weight: .heavy),
                .foregroundColor: UIColor.white,
                .paragraphStyle: style
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            ctx.cgContext.setShadow(offset: CGSize(width: 0, height: 3), blur: 6,
                                    color: UIColor.black.withAlphaComponent(0.3).cgColor)
            text.draw(in: textRect, withAttributes: attrs)
            
            // DEMO tag
            ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            let tag = "DEMO"
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            let tagSize = tag.size(withAttributes: tagAttrs)
            let pad: CGFloat = 8
            let tagBg = CGRect(
                x: size.width - tagSize.width - pad * 2 - 20,
                y: 24,
                width: tagSize.width + pad * 2,
                height: tagSize.height + pad
            )
            UIColor.black.withAlphaComponent(0.45).setFill()
            UIBezierPath(roundedRect: tagBg, cornerRadius: 8).fill()
            tag.draw(in: CGRect(x: tagBg.minX + pad, y: tagBg.minY + pad / 2,
                                width: tagSize.width, height: tagSize.height),
                     withAttributes: tagAttrs)
        }
    }
}
