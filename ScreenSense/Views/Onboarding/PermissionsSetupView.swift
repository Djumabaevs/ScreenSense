import SwiftUI

struct PermissionsSetupView: View {
    let onComplete: () -> Void
    @State private var screenTimeService = ScreenTimeService.shared
    @State private var screenTimeGranted = false
    @State private var screenTimeError: String?
    @State private var notificationsGranted = false
    @State private var showNotificationsSettingsAlert = false
    @State private var bedtimeHour = 23
    @State private var wakeupHour = 7
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Let's Set Things Up")
                .font(.title2.bold())
            
            VStack(spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Screen Time Access", systemImage: "iphone")
                                    .font(.headline)
                                Text("Required to see your app usage data")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if screenTimeGranted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title2)
                            } else {
                                GlassButton("Allow", style: .secondary) {
                                    Task {
                                        await requestScreenTimeAccess()
                                    }
                                }
                                .frame(width: 100)
                            }
                        }

                        if let screenTimeError {
                            Text(screenTimeError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Notifications", systemImage: "bell.fill")
                                .font(.headline)
                            Text("Gentle nudges when you scroll too long")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if notificationsGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                        } else {
                            GlassButton("Enable", style: .secondary) {
                                Task {
                                    await requestNotificationsAccess()
                                }
                            }
                            .frame(width: 100)
                        }
                    }
                }
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your Schedule", systemImage: "bed.double.fill")
                            .font(.headline)
                        
                        HStack {
                            Text("Bedtime")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("Bedtime", selection: $bedtimeHour) {
                                ForEach(20..<25) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Wake up")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("Wake up", selection: $wakeupHour) {
                                ForEach(5..<11) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            GlassButton("Start Sensing!", style: .primary) {
                Task {
                    await completeSetup()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
        .task {
            screenTimeService.checkAuthorizationStatus()
            screenTimeGranted = screenTimeService.isAuthorized
            notificationsGranted = await NotificationService.shared.hasPermission()
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

    @MainActor
    private func requestScreenTimeAccess() async {
        await screenTimeService.requestAuthorization()
        screenTimeGranted = screenTimeService.isAuthorized
        screenTimeError = screenTimeService.authorizationError?.localizedDescription
    }

    @MainActor
    private func requestNotificationsAccess() async {
        notificationsGranted = await NotificationService.shared.requestPermissionIfNeeded()
        if !notificationsGranted {
            showNotificationsSettingsAlert = true
        }
    }

    @MainActor
    private func completeSetup() async {
        UserDefaults.standard.set(bedtimeHour, forKey: UserDefaultsKeys.bedtimeHour)
        UserDefaults.standard.set(wakeupHour, forKey: UserDefaultsKeys.wakeupHour)
        NotificationService.shared.registerCategories()

        if !screenTimeGranted {
            await requestScreenTimeAccess()
        }

        guard screenTimeGranted else {
            if screenTimeError == nil {
                screenTimeError = "Screen Time access is required to collect usage data."
            }
            return
        }

        if !notificationsGranted {
            await requestNotificationsAccess()
        }

        screenTimeService.startMonitoringIfAuthorized()
        onComplete()
    }
}
