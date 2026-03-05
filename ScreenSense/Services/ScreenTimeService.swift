import Foundation
import FamilyControls
import DeviceActivity
import SwiftData

@Observable
final class ScreenTimeService {
    static let shared = ScreenTimeService()

    private let activityCenter = DeviceActivityCenter()
    private let activityName = DeviceActivityName("screensense.daily.monitoring")

    var isAuthorized = false
    var authorizationError: Error?
    var monitoringError: String?

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                self.isAuthorized = true
                self.authorizationError = nil
            }
            print("[ScreenTimeService] Authorization granted")
            startMonitoringIfAuthorized()
        } catch {
            print("[ScreenTimeService] Authorization failed: \(error)")
            await MainActor.run {
                self.isAuthorized = false
                self.authorizationError = error
            }
        }
    }

    func checkAuthorizationStatus() {
        let status = AuthorizationCenter.shared.authorizationStatus
        isAuthorized = (status == .approved)
    }

    func requestAuthorizationIfNeeded() async {
        let status = AuthorizationCenter.shared.authorizationStatus
        if status == .notDetermined {
            await requestAuthorization()
            return
        }

        await MainActor.run {
            self.isAuthorized = (status == .approved)
            self.authorizationError = nil
        }
    }

    // MARK: - Monitoring with Goal-Based Thresholds

    /// Starts monitoring with thresholds derived from the user's active goals.
    /// Call this whenever goals are created, updated, or deleted.
    func startMonitoringIfAuthorized() {
        checkAuthorizationStatus()
        guard isAuthorized else {
            monitoringError = "Screen Time authorization has not been granted."
            print("[ScreenTimeService] Not authorized, skipping monitoring start")
            return
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true,
            warningTime: DateComponents(minute: 5)
        )

        // Build events from goal definitions in shared storage
        var events = buildGoalEvents()

        // Always have a fallback 2-hour general threshold if no screen time goals exist
        if events.isEmpty {
            let fallbackEvent = DeviceActivityEvent(
                threshold: DateComponents(hour: 2)
            )
            events[DeviceActivityEvent.Name("screensense.fallback.2h")] = fallbackEvent
        }

        do {
            activityCenter.stopMonitoring([activityName])
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: events
            )
            monitoringError = nil
            print("[ScreenTimeService] Monitoring started with \(events.count) threshold events")
            for (name, _) in events {
                print("[ScreenTimeService]   → \(name.rawValue)")
            }
        } catch {
            monitoringError = error.localizedDescription
            print("[ScreenTimeService] Monitoring failed: \(error)")
        }
    }

    /// Builds DeviceActivityEvents from the user's active goal definitions.
    /// - reduceTotal goals → threshold at target minutes + warning at 80%
    /// - reducePickups goals → not supported by DeviceActivityEvent (count-based)
    /// - reduceApp goals → threshold at target minutes (total device, not per-app)
    private func buildGoalEvents() -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        let goalDefs = loadGoalDefinitions()
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        let checkEighty = UserDefaults.standard.object(forKey: UserDefaultsKeys.alertAtEightyPercent) as? Bool ?? true
        let checkHundred = UserDefaults.standard.object(forKey: UserDefaultsKeys.alertAtOneHundredPercent) as? Bool ?? true

        for def in goalDefs {
            let targetMinutes = Int(def.targetValue)

            switch def.typeRaw {
            case "reduceTotal":
                // 100% threshold — goal limit reached
                if checkHundred && targetMinutes > 0 {
                    let hours = targetMinutes / 60
                    let mins = targetMinutes % 60
                    let event = DeviceActivityEvent(
                        threshold: DateComponents(hour: hours, minute: mins)
                    )
                    let name = DeviceActivityEvent.Name("goal.reduceTotal.\(def.id).100")
                    events[name] = event
                }

                // 80% warning threshold
                if checkEighty && targetMinutes > 0 {
                    let warningMinutes = Int(Double(targetMinutes) * 0.8)
                    let hours = warningMinutes / 60
                    let mins = warningMinutes % 60
                    let event = DeviceActivityEvent(
                        threshold: DateComponents(hour: hours, minute: mins)
                    )
                    let name = DeviceActivityEvent.Name("goal.reduceTotal.\(def.id).80")
                    events[name] = event
                }

            case "reduceApp":
                // Per-app thresholds use total device time as approximation
                // (true per-app thresholds require ApplicationToken from FamilyControls picker)
                if checkHundred && targetMinutes > 0 {
                    let hours = targetMinutes / 60
                    let mins = targetMinutes % 60
                    let event = DeviceActivityEvent(
                        threshold: DateComponents(hour: hours, minute: mins)
                    )
                    let appLabel = def.relatedAppName ?? "app"
                    let name = DeviceActivityEvent.Name("goal.reduceApp.\(def.id).100")
                    events[name] = event
                    print("[ScreenTimeService] App limit for \(appLabel): \(targetMinutes)m (total device proxy)")
                }

            default:
                break
            }
        }

        return events
    }

    // MARK: - Schedule Bedtime & Morning Notifications

    /// Schedules bedtime nudges and morning summaries based on active goals and user settings.
    /// Call this from the main app on launch and when goals/settings change.
    func scheduleGoalNotifications() {
        let goalDefs = loadGoalDefinitions()
        let nudgeScheduler = NudgeScheduler.shared

        // Bedtime nudge for noPhoneAfter goals
        for def in goalDefs where def.typeRaw == "noPhoneAfter" {
            let hour = Int(def.targetValue)
            if hour > 0 && hour < 24 {
                nudgeScheduler.scheduleBedtimeNudge(bedtimeHour: hour)
                print("[ScreenTimeService] Scheduled bedtime nudge at \(hour):00")
            }
        }

        // Morning summary
        let morningSummaryEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.morningSummaryEnabled) as? Bool ?? true
        if morningSummaryEnabled {
            let wakeupHour = UserDefaults.standard.integer(forKey: UserDefaultsKeys.wakeupHour)
            let hour = wakeupHour > 0 ? wakeupHour : AppConstants.defaultWakeupHour
            nudgeScheduler.scheduleMorningSummary(hour: hour, score: 0, totalTime: 0)
            print("[ScreenTimeService] Scheduled morning summary at \(hour):00")
        }
    }

    // MARK: - Data Loading

    private func loadGoalDefinitions() -> [SharedGoalDefinition] {
        // Try file first
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
            let fileURL = containerURL.appendingPathComponent("goal_definitions.json")
            if let data = try? Data(contentsOf: fileURL),
               let defs = try? JSONDecoder().decode([SharedGoalDefinition].self, from: data) {
                return defs
            }
        }

        // Fallback to UserDefaults
        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            defaults.synchronize()
            if let data = defaults.data(forKey: "goalDefinitions"),
               let defs = try? JSONDecoder().decode([SharedGoalDefinition].self, from: data) {
                return defs
            }
        }

        return []
    }

    @MainActor
    func syncLatestData(modelContext: ModelContext) {
        ScreenTimeDataSyncService.shared.syncLatestDailyData(into: modelContext)
    }
}
