import SwiftUI

struct NotificationsSettingsView: View {
    @AppStorage("notificationsEnabled") private var nudgesEnabled = true
    @AppStorage("nudgeFrequency") private var nudgeFrequency = "Normal"
    @AppStorage("nudgeStyle") private var nudgeStyle = "Gentle"
    @AppStorage("morningSummaryEnabled") private var morningSummary = true
    @AppStorage("eveningDigestEnabled") private var eveningDigest = true
    @AppStorage("weeklyDigestEnabled") private var weeklyDigest = true
    
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
                Toggle("At 80% of limit", isOn: .constant(true))
                Toggle("At 100% of limit", isOn: .constant(true))
                Toggle("Streak broken", isOn: .constant(true))
                Toggle("Achievement earned", isOn: .constant(true))
            }
        }
        .navigationTitle("Notifications")
    }
}
