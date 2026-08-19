// MARK: - Celebration Toast
import SwiftUI

struct CelebrationView: View {
    let frameCount: Int
    @State private var showContent = false
    @State private var particles: [(id: Int, symbol: String, x: CGFloat, y: CGFloat, opacity: Double)] = []

    private var milestone: Int {
        (frameCount / 10) * 10
    }

    private let symbols = ["star.fill", "sparkles", "party.popper.fill", "film.fill", "video.fill", "crown.fill"]

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.appYellow.opacity(0.3), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )

            // Floating SF symbol particles
            ForEach(particles, id: \.id) { item in
                Image(systemName: item.symbol)
                    .font(.system(size: CGFloat.random(in: 24...36), weight: .bold))
                    .foregroundStyle(Color.candyAccents.randomElement()!)
                    .offset(x: item.x, y: item.y)
                    .opacity(item.opacity)
            }

            VStack(spacing: 16) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appYellow, .appOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showContent ? 1.0 : 0.3)

                VStack(spacing: 8) {
                    Text("Awesome!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("You just captured \(milestone) frames!")
                        .font(.system(.callout, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0.0)
            }
        }
        .onAppear {
            spawnParticles()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showContent = true
            }
        }
    }

    private func spawnParticles() {
        for i in 0..<20 {
            let item = (
                id: i,
                symbol: symbols.randomElement()!,
                x: CGFloat.random(in: -180...180),
                y: CGFloat.random(in: -300...300),
                opacity: Double.random(in: 0.5...1.0)
            )
            particles.append(item)
        }
        withAnimation(.easeOut(duration: 2.5)) {
            particles = particles.map { item in
                (id: item.id, symbol: item.symbol, x: item.x, y: item.y + CGFloat.random(in: 80...200), opacity: 0.0)
            }
        }
    }
}
