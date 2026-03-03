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

    var shadowRadius: CGFloat {
        switch self {
        case .regular: return 12
        case .elevated: return 20
        case .subtle: return 8
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .regular: return 0.08
        case .elevated: return 0.12
        case .subtle: return 0.05
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
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.20), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowRadius, y: style.shadowRadius / 3)
            .opacity(style.opacity)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 16) {
            GlassCard {
                Text("Regular Glass")
                    .foregroundStyle(.white)
            }
            GlassCard(style: .elevated) {
                Text("Elevated Glass")
                    .foregroundStyle(.white)
            }
            GlassCard(style: .subtle) {
                Text("Subtle Glass")
                    .foregroundStyle(.white)
            }
        }
        .padding()
    }
}
