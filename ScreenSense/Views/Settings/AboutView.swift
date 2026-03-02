import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        Text("ScreenSense")
                            .font(.title2.bold())
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            
            Section {
                Link(destination: URL(string: "https://screensense.app/privacy")!) {
                    Label("Privacy Policy", systemImage: "lock.fill")
                }
                Link(destination: URL(string: "https://screensense.app/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                }
            }
        }
        .navigationTitle("About")
    }
}
