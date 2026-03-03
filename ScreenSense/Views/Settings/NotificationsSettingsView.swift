import SwiftUI

struct NotificationsSettingsView: View {
    @AppStorage(UserDefaultsKeys.notificationsEnabled) private var nudgesEnabled = true
    @AppStorage(UserDefaultsKeys.nudgeFrequency) private var nudgeFrequency = "Normal"
    @AppStorage(UserDefaultsKeys.nudgeStyle) private var nudgeStyle = "Gentle"
    @AppStorage(UserDefaultsKeys.morningSummaryEnabled) private var morningSummary = true
    @AppStorage(UserDefaultsKeys.eveningDigestEnabled) private var eveningDigest = true
    @AppStorage(UserDefaultsKeys.weeklyDigestEnabled) private var weeklyDigest = true
    @AppStorage(UserDefaultsKeys.alertAtEightyPercent) private var alertAtEightyPercent = true
    @AppStorage(UserDefaultsKeys.alertAtOneHundredPercent) private var alertAtOneHundredPercent = true
    @AppStorage(UserDefaultsKeys.alertOnStreakBroken) private var alertOnStreakBroken = true
    @AppStorage(UserDefaultsKeys.alertOnAchievementEarned) private var alertOnAchievementEarned = true
    @State private var showNotificationsSettingsAlert = false
    
    var body: some View {
        List {
            Section("Nudges") {
                Toggle("Enable Nudges", isOn: $nudgesEnabled)
                
                if nudgesEnabled {
                    Picker("Frequency", selection: $nudgeFrequency) {
                        Text("Rare").tag("Rare")
                        Text("Normal").tag("Normal")
                        Text("Often").tag("Often")
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Nudge Style", selection: $nudgeStyle) {
                        Text("Gentle").tag("Gentle")
                        Text("Direct").tag("Direct")
                        Text("Fun").tag("Fun")
                    }
                }
            }
            
            Section("Scheduled") {
                Toggle("Morning Summary", isOn: $morningSummary)
                Toggle("Evening Digest", isOn: $eveningDigest)
                Toggle("Weekly Digest", isOn: $weeklyDigest)
            }
            
            Section("Goal Alerts") {
                Toggle("At 80% of limit", isOn: $alertAtEightyPercent)
                Toggle("At 100% of limit", isOn: $alertAtOneHundredPercent)
                Toggle("Streak broken", isOn: $alertOnStreakBroken)
                Toggle("Achievement earned", isOn: $alertOnAchievementEarned)
            }
        }
        .navigationTitle("Notifications")
        .task {
            let granted = await NotificationService.shared.hasPermission()
            if !granted {
                nudgesEnabled = false
            }
        }
        .onChange(of: nudgesEnabled) { _, newValue in
            guard newValue else { return }
            Task {
                let granted = await NotificationService.shared.requestPermissionIfNeeded()
                if granted {
                    NotificationService.shared.registerCategories()
                } else {
                    await MainActor.run {
                        nudgesEnabled = false
                        showNotificationsSettingsAlert = true
                    }
                }
            }
        }
        .alert("Notifications Disabled", isPresented: $showNotificationsSettingsAlert) {
            Button("Not Now", role: .cancel) {}
            Button("Open Settings") {
                NotificationService.shared.openSystemSettings()
            }
        } message: {
            Text("Enable notifications in iPhone Settings to receive nudges and goal alerts.")
        }
    }
}
