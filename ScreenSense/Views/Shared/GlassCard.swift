import SwiftUI

enum GlassCardStyle {
    case regular
    case elevated
    case subtle
    
    var material: Material {
        switch self {
        case .regular: return .ultraThinMaterial
        case .elevated: return .regularMaterial
        case .subtle: return .ultraThinMaterial
        }
    }
    
    var opacity: Double {
        switch self {
        case .regular: return 1.0
        case .elevated: return 1.0
        case .subtle: return 0.7
        }
    }
}

struct GlassCard<Content: View>: View {
    let style: GlassCardStyle
    @ViewBuilder let content: Content
    
    init(style: GlassCardStyle = .regular, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(style.material, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .opacity(style.opacity)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        GlassCard {
            Text("Hello, Glass!")
                .foregroundStyle(.white)
        }
        .padding()
    }
}
