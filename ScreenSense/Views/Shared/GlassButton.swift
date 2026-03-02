import SwiftUI

enum GlassButtonStyle {
    case primary
    case secondary
    case ghost
}

struct GlassButton: View {
    let title: String
    let style: GlassButtonStyle
    let action: () -> Void
    
    init(_ title: String, style: GlassButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(backgroundView)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(overlayView)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Color.accentColor
        case .secondary:
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        case .ghost:
            Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .accentColor
        case .ghost: return .accentColor
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        } else {
            EmptyView()
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassButton("Primary Button", style: .primary) {}
        GlassButton("Secondary Button", style: .secondary) {}
        GlassButton("Ghost Button", style: .ghost) {}
    }
    .padding()
}
