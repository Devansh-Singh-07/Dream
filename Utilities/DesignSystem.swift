//
//  DesignSystem.swift
//  classMotion
//
//  Created by devansh pratap singh on 24/02/26.
//

import SwiftUI

// MARK: - Candy Pop Color Palette
extension Color {
    // Primary accent color (Sky Blue)
    static let appAccent = appBlue
    static let appBlue = Color(red: 0.29, green: 0.56, blue: 1.0)     // #4A90FF Sky Blue
    static let appGreen = Color(red: 0.20, green: 0.83, blue: 0.60)   // #34D399 Mint Green
    static let appOrange = Color(red: 0.98, green: 0.57, blue: 0.24)  // #FB923C Tangerine
    static let appPurple = Color(red: 0.65, green: 0.55, blue: 0.98)  // #A78BFA Lavender
    static let appRed = Color(red: 0.97, green: 0.44, blue: 0.44)     // #F87171 Coral
    static let appPink = Color(red: 0.96, green: 0.45, blue: 0.71)    // #F472B6 Bubblegum
    static let appYellow = Color(red: 0.98, green: 0.75, blue: 0.14)  // #FBBF24 Sunshine

    // Backgrounds (Adaptive for Light & Dark mode)
    static let bgCanvas = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.11, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1.0)
    })

    static let bgCard = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.14, blue: 0.18, alpha: 1.0)
            : UIColor.white
    })

    // Semantic (legacy compat) - Using Sky Blue (appBlue) as primary accent
    static let studentPrimary = appBlue
    static let teacherPrimary = appGreen
    static let inProgress = appBlue
    static let submitted = appOrange
    static let graded = appGreen

    // Grade colors
    static func gradeColor(_ grade: String) -> Color {
        if grade.hasPrefix("A") { return .appGreen }
        if grade.hasPrefix("B") { return .appPurple }
        if grade.hasPrefix("C") { return .appOrange }
        return .appRed
    }

    // Rotating candy accent for cards
    static let candyAccents: [Color] = [.appPurple, .appBlue, .appPink, .appOrange, .appGreen, .appYellow]
    static func candyAccent(for index: Int) -> Color {
        candyAccents[index % candyAccents.count]
    }
}

// MARK: - ShapeStyle Extensions for Color Tokens
extension ShapeStyle where Self == Color {
    static var appAccent: Color { .appBlue }
    static var appBlue: Color { .appBlue }
    static var appGreen: Color { .appGreen }
    static var appOrange: Color { .appOrange }
    static var appPurple: Color { .appPurple }
    static var appRed: Color { .appRed }
    static var appPink: Color { .appPink }
    static var appYellow: Color { .appYellow }
    static var bgCanvas: Color { .bgCanvas }
    static var bgCard: Color { .bgCard }
}

// MARK: - Rainbow Gradient
extension LinearGradient {
    static let rainbow = LinearGradient(
        colors: [.appBlue, .appPurple, .appPink, .appOrange, .appYellow, .appGreen],
        startPoint: .leading,
        endPoint: .trailing
    )
    static let rainbowDiagonal = LinearGradient(
        colors: [.appBlue, .appPurple, .appPink, .appOrange, .appYellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Fonts (Dynamic Type, Rounded)
extension Font {
    static let appTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let appLargeTitle = Font.system(.title, design: .rounded, weight: .bold)
    static let appHeadline = Font.system(.headline, design: .rounded, weight: .bold)
    static let appSubheadline = Font.system(.subheadline, design: .rounded)
    static let appBody = Font.system(.body, design: .rounded)
    static let appCaption = Font.system(.caption, design: .rounded)

    static func scaledSystem(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .rounded) -> Font {
        Font.system(size: size, weight: weight, design: design)
    }
}

// MARK: - Spacing
extension CGFloat {
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 40

    static let cornerRadius: CGFloat = 24
    static let cornerRadiusSmall: CGFloat = 18
}

// MARK: - Candy Card Modifier
struct CandyCardStyle: ViewModifier {
    var accentColor: Color = .appBlue

    func body(content: Content) -> some View {
        content
            .padding(.spacingL)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius, style: .continuous)
                    .stroke(accentColor.opacity(0.2), lineWidth: 2)
            }
            .shadow(color: accentColor.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Primary Button Modifier
struct CandyPrimaryButtonStyle: ViewModifier {
    let color: Color
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .font(.appHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                isDisabled
                    ? AnyShapeStyle(Color.gray.opacity(0.4))
                    : AnyShapeStyle(LinearGradient(
                        colors: [color, color.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .clipShape(Capsule())
            .shadow(color: isDisabled ? .clear : color.opacity(0.35), radius: 15, x: 0, y: 8)
    }
}

struct CandySecondaryButtonStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.appHeadline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Glass Effect Modifier
struct GlassEffectStyle: ViewModifier {
    var cornerRadius: CGFloat = .cornerRadiusSmall
    var accentColor: Color = .white

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(accentColor.opacity(0.25), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

// MARK: - View Extensions
extension View {
    func glassEffect(cornerRadius: CGFloat = .cornerRadiusSmall, accent: Color = .white) -> some View {
        modifier(GlassEffectStyle(cornerRadius: cornerRadius, accentColor: accent))
    }

    func glassCapsule(accent: Color = .white) -> some View {
        self
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(accent.opacity(0.25), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
    }

    func candyCard(accent: Color = .appBlue) -> some View {
        modifier(CandyCardStyle(accentColor: accent))
    }

    // Legacy compat
    func glassCard() -> some View {
        candyCard()
    }
    func cardStyle() -> some View {
        candyCard()
    }

    func primaryButton(color: Color = .appBlue, isDisabled: Bool = false) -> some View {
        modifier(CandyPrimaryButtonStyle(color: color, isDisabled: isDisabled))
    }

    func secondaryButton(color: Color = .appBlue) -> some View {
        modifier(CandySecondaryButtonStyle(color: color))
    }

    func smoothTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    // Haptic helpers
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    func hapticWarning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    func hapticError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func cardPressAnimation() -> some View {
        self.buttonStyle(BubbleButtonStyle())
    }

    func springAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(.spring(response: 0.35, dampingFraction: 0.65), value: value)
    }

    // Force light mode on the whole view
    func forceLightMode() -> some View {
        self.preferredColorScheme(.light)
    }
}

// MARK: - Global Haptic Helpers
func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}
func hapticSuccess() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}

// MARK: - Bubble Button Style (Bouncy)
struct BubbleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Legacy compat
typealias CardPressButtonStyle = BubbleButtonStyle

// MARK: - Animated Candy Background
struct CandyBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Color.bgCanvas

            // Floating pastel blobs
            Circle()
                .fill(Color.appBlue.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -100 + sin(phase * 0.7) * 30, y: -200 + cos(phase * 0.5) * 20)

            Circle()
                .fill(Color.appPink.opacity(0.07))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: 120 + cos(phase * 0.6) * 25, y: 100 + sin(phase * 0.8) * 15)

            Circle()
                .fill(Color.appPurple.opacity(0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 45)
                .offset(x: -50 + cos(phase * 0.4) * 20, y: 300 + sin(phase * 0.6) * 25)

            Circle()
                .fill(Color.appYellow.opacity(0.06))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: 150 + sin(phase * 0.5) * 15, y: -100 + cos(phase * 0.7) * 20)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

// Legacy compat
struct MeshGradientBackground: View {
    var body: some View {
        CandyBackground()
    }
}

extension View {
    func glassBackground() -> some View {
        ZStack {
            CandyBackground()
            self
        }
    }
}

// MARK: - Reusable Components
struct SectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: .spacingS) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.appBlue)
            }
            Text(title)
                .font(.appHeadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appBlue.opacity(0.5), .appPink.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce)

            Text(title)
                .font(.appLargeTitle)

            Text(message)
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

struct StatusBadge: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color, in: Capsule())
    }
}

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: .spacingL) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.appBlue)

            Text(message)
                .font(.appHeadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct IconBadge: View {
    let icon: String
    let color: Color
    let size: CGFloat

    init(_ icon: String, color: Color, size: CGFloat = 60) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .shadow(color: color.opacity(0.35), radius: 10, x: 0, y: 5)
    }
}
