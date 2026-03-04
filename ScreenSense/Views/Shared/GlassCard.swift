import SwiftUI
import UIKit

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

// MARK: - Liquid Glass Button Style

/// A button style that applies a liquid glass press effect:
/// scale down + brightness shift + highlight overlay on press, with spring animation.
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(configuration.isPressed ? 0.08 : 0))
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A tappable GlassCard that applies liquid glass press feedback with haptics.
struct TappableGlassCard<Content: View>: View {
    let style: GlassCardStyle
    let action: () -> Void
    @ViewBuilder let content: Content

    init(style: GlassCardStyle = .regular, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.style = style
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            GlassCard(style: style) {
                content
            }
        }
        .buttonStyle(LiquidGlassButtonStyle())
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
            TappableGlassCard(style: .elevated, action: {}) {
                Text("Tappable Elevated Glass")
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

// MARK: - Passthrough View (for DeviceActivityReport in ScrollView)

/// Wraps content in a UIKit view that passes ALL touches through.
/// Fixes ExtensionKit remote views capturing scroll gestures.
struct PassthroughView<Content: View>: UIViewRepresentable {
    let content: Content

    func makeUIView(context: Context) -> PassthroughContainerView {
        let container = PassthroughContainerView()
        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.view.isUserInteractionEnabled = false
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        context.coordinator.hostingController = hosting
        return container
    }

    func updateUIView(_ uiView: PassthroughContainerView, context: Context) {
        context.coordinator.hostingController?.rootView = content
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var hostingController: UIHostingController<Content>?
    }
}

/// Returns nil from hitTest — all touches pass through to parent ScrollView.
class PassthroughContainerView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}
