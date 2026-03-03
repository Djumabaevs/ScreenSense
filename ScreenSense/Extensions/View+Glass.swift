import SwiftUI

extension View {
    func glassCard(style: GlassCardStyle = .regular) -> some View {
        self
            .padding()
            .background(style.material, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
    }

    func springAppear(delay: Double = 0) -> some View {
        self.modifier(SpringAppearModifier(delay: delay))
    }

    /// Adds a liquid glass shimmer highlight effect on scroll.
    func liquidGlassShimmer(isActive: Bool = true) -> some View {
        self.modifier(LiquidGlassShimmerModifier(isActive: isActive))
    }
}

struct SpringAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1 : 0.97)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

/// A shimmer effect modifier that creates a subtle moving highlight across a card.
struct LiquidGlassShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.08),
                                .white.opacity(0.12),
                                .white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: phase * (geo.size.width * 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            )
            .clipped()
            .onAppear {
                guard isActive else { return }
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                    .delay(Double.random(in: 0...1))
                ) {
                    phase = 1
                }
            }
    }
}
