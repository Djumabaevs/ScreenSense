import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title3.bold())
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle, let action {
                GlassButton(actionTitle, style: .secondary, action: action)
                    .frame(width: 200)
            }
        }
        .padding(40)
    }
}
