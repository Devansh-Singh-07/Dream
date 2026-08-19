import SwiftUI

/// Full-screen celebration overlay shown when a student levels up.
/// Clean, SF-symbol-powered confetti animation.
struct LevelUpView: View {
    let newLevel: Int
    var onDismiss: () -> Void = {}
    
    @State private var showContent = false
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            // Bright overlay
            Color(uiColor: .systemBackground).opacity(0.92)
                .ignoresSafeArea()
                .onTapGesture { dismissWithAnimation() }
            
            // Confetti particles — SF symbol icons
            ForEach(particles) { particle in
                Image(systemName: particle.sfSymbol)
                    .font(.system(size: particle.size, weight: .bold))
                    .foregroundStyle(particle.color)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
            }
            
            // Center card
            VStack(spacing: 28) {
                // Trophy/Sparkles
                Image(systemName: "trophy.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appYellow, .appOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showContent ? 1.0 : 0.2)
                    .opacity(showContent ? 1.0 : 0.0)
                
                // Level text
                VStack(spacing: 10) {
                    Text("LEVEL UP!")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(LinearGradient.rainbow)
                        .tracking(4)
                    
                    Text("\(newLevel)")
                        .font(.system(size: 96, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient.rainbowDiagonal
                        )
                    
                    Text("You're UNSTOPPABLE!")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0.0)
                
                // Dismiss button
                Button(action: dismissWithAnimation) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Let's Go!")
                    }
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 16)
                    .background(LinearGradient.rainbow)
                    .clipShape(Capsule())
                    .shadow(color: .appBlue.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .buttonStyle(BubbleButtonStyle())
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1.0 : 0.0)
            }
            .padding(44)
            .background(
                Color.bgCard
                    .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(LinearGradient.rainbow, lineWidth: 3)
            }
            .shadow(color: .appBlue.opacity(0.15), radius: 30, x: 0, y: 15)
            .padding(.horizontal, 40)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            spawnConfetti()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                showContent = true
            }
            // Auto-dismiss after 4 seconds
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                dismissWithAnimation()
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showContent = false
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            onDismiss()
        }
    }
    
    private func spawnConfetti() {
        let symbols = ["star.fill", "sparkles", "trophy.fill", "award.fill", "film.fill", "flame.fill", "bolt.fill", "crown.fill"]
        for i in 0..<50 {
            let particle = ConfettiParticle(
                id: i,
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: -400...400),
                size: CGFloat.random(in: 16...32),
                color: Color.candyAccents.randomElement()!,
                opacity: Double.random(in: 0.5...1.0),
                sfSymbol: symbols.randomElement()!,
                rotation: Double.random(in: -30...30)
            )
            particles.append(particle)
        }
        
        // Animate particles drifting
        withAnimation(.easeOut(duration: 3.5)) {
            particles = particles.map { p in
                var updated = p
                updated.y += CGFloat.random(in: 120...300)
                updated.opacity = 0
                updated.rotation += Double.random(in: -90...90)
                return updated
            }
        }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    var opacity: Double
    var sfSymbol: String
    var rotation: Double
}
