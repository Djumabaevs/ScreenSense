import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false

    private var memberSinceDate: Date {
        UserDefaults.standard.object(forKey: UserDefaultsKeys.installationDate) as? Date ?? Date()
    }

    var body: some View {
        NavigationStack {
            List {
                profileSection
                generalSection
                dataPrivacySection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Delete all data?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This removes your reports, insights, goals, moods, and digests from this device.")
            }
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
                    Text("Member since \(memberSinceDate.dayMonthString)")
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
                PermissionsSettingsView()
            } label: {
                Label("Permissions", systemImage: "hand.raised.fill")
            }

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
                showDeleteConfirmation = true
            } label: {
                Label("Delete All Data", systemImage: "trash.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Link(destination: URL(string: "itms-apps://apps.apple.com")!) {
                Label("Rate ScreenSense", systemImage: "heart.fill")
            }

            Link(destination: URL(string: "mailto:djumabaevb@gmail.com")!) {
                Label("Send Feedback", systemImage: "envelope.fill")
            }

            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.1")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func deleteAllData() {
        do {
            try deleteAll(DailyReport.self)
            try deleteAll(AppUsageEntry.self)
            try deleteAll(Insight.self)
            try deleteAll(UserGoal.self)
            try deleteAll(MoodEntry.self)
            try deleteAll(WeeklyDigest.self)
            try modelContext.save()
        } catch {
            print("[SettingsView] Failed to delete local data: \(error)")
        }

        AppGroupManager.shared.remove(forKey: UserDefaultsKeys.sharedLatestDailyData)
        AppGroupManager.shared.remove(forKey: UserDefaultsKeys.sharedLatestDailyDataUpdatedAt)
        AppGroupManager.shared.remove(forKey: UserDefaultsKeys.reportLastGeneratedAt)
        AppGroupManager.shared.remove(forKey: UserDefaultsKeys.reportLastGeneratedTotalScreenTime)
        AppGroupManager.shared.remove(forKey: UserDefaultsKeys.reportLastGeneratedAppCount)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.sharedLastImportedDataUpdatedAt)
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        let descriptor = FetchDescriptor<T>()
        let objects = try modelContext.fetch(descriptor)
        for object in objects {
            modelContext.delete(object)
        }
    }
}
