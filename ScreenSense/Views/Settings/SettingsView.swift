import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                profileSection
                generalSection
                dataPrivacySection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your ScreenSense")
                        .font(.headline)
                    Text("Member since \(Date().dayMonthString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var generalSection: some View {
        Section("General") {
            NavigationLink {
                NotificationsSettingsView()
            } label: {
                Label("Notifications", systemImage: "bell.fill")
            }

            NavigationLink {
                AppearanceSettingsView()
            } label: {
                Label("Appearance", systemImage: "paintbrush.fill")
            }
        }
    }

    private var dataPrivacySection: some View {
        Section("Data & Privacy") {
            NavigationLink {
                PrivacyInfoView()
            } label: {
                Label("Privacy Info", systemImage: "lock.fill")
            }

            Button(role: .destructive) {
            } label: {
                Label("Delete All Data", systemImage: "trash.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Link(destination: URL(string: "https://apps.apple.com")!) {
                Label("Rate ScreenSense", systemImage: "heart.fill")
            }

            Link(destination: URL(string: "mailto:support@screensense.app")!) {
                Label("Send Feedback", systemImage: "envelope.fill")
            }

            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
