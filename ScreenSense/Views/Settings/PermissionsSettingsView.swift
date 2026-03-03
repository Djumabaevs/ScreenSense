import SwiftUI
import FamilyControls

struct PermissionsSettingsView: View {
    @State private var screenTimeService = ScreenTimeService.shared
    @State private var notificationsAuthorized = false
    @State private var showNotificationsSettingsAlert = false

    var body: some View {
        List {
            Section("Screen Time") {
                HStack {
                    Label("Access", systemImage: "iphone")
                    Spacer()
                    statusPill(isEnabled: screenTimeService.isAuthorized)
                }

                Button("Allow Screen Time Access") {
                    Task {
                        await screenTimeService.requestAuthorization()
                        screenTimeService.startMonitoringIfAuthorized()
                    }
                }

                if !screenTimeService.isAuthorized {
                    Button("Open iPhone Settings") {
                        NotificationService.shared.openSystemSettings()
                    }
                }

                if let error = screenTimeService.authorizationError {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Notifications") {
                HStack {
                    Label("Access", systemImage: "bell.fill")
                    Spacer()
                    statusPill(isEnabled: notificationsAuthorized)
                }

                Button("Allow Notifications") {
                    Task {
                        let granted = await NotificationService.shared.requestPermissionIfNeeded()
                        await MainActor.run {
                            notificationsAuthorized = granted
                            showNotificationsSettingsAlert = !granted
                        }
                    }
                }
            }
        }
        .navigationTitle("Permissions")
        .task {
            screenTimeService.checkAuthorizationStatus()
            notificationsAuthorized = await NotificationService.shared.hasPermission()
        }
        .onAppear {
            screenTimeService.checkAuthorizationStatus()
        }
        .alert("Notifications Disabled", isPresented: $showNotificationsSettingsAlert) {
            Button("Not Now", role: .cancel) {}
            Button("Open Settings") {
                NotificationService.shared.openSystemSettings()
            }
        } message: {
            Text("Enable notifications in iPhone Settings to receive nudges and alerts.")
        }
    }

    private func statusPill(isEnabled: Bool) -> some View {
        Text(isEnabled ? "Allowed" : "Not Allowed")
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(isEnabled ? Color.green : Color.red)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}
