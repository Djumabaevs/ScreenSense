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
}

struct SpringAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
}
