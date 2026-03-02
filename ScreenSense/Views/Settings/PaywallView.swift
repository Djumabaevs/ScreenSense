import SwiftUI

// All features are free — paywall removed.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        EmptyView()
            .onAppear { dismiss() }
    }
}
