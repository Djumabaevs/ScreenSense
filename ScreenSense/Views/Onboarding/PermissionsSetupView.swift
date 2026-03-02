import SwiftUI

struct PermissionsSetupView: View {
    let onComplete: () -> Void
    @State private var screenTimeService = ScreenTimeService.shared
    @State private var screenTimeGranted = false
    @State private var screenTimeError: String?
    @State private var notificationsGranted = false
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
                                        await screenTimeService.requestAuthorization()
                                        screenTimeGranted = screenTimeService.isAuthorized
                                        if let error = screenTimeService.authorizationError {
                                            screenTimeError = error.localizedDescription
                                        }
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
                                    notificationsGranted = await NotificationService.shared.requestPermission()
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
                UserDefaults.standard.set(bedtimeHour, forKey: UserDefaultsKeys.bedtimeHour)
                UserDefaults.standard.set(wakeupHour, forKey: UserDefaultsKeys.wakeupHour)
                onComplete()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
    }
}
