import Foundation
import FamilyControls
import DeviceActivity
import SwiftData

@Observable
final class ScreenTimeService {
    static let shared = ScreenTimeService()

    private let activityCenter = DeviceActivityCenter()
    private let activityName = DeviceActivityName("screensense.daily.monitoring")
    private let thresholdEventName = DeviceActivityEvent.Name("screensense.daily.threshold")

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

        let usageThreshold = DeviceActivityEvent(
            threshold: DateComponents(hour: 2)
        )

        do {
            activityCenter.stopMonitoring([activityName])
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: [thresholdEventName: usageThreshold]
            )
            monitoringError = nil
            print("[ScreenTimeService] Monitoring started successfully")
        } catch {
            monitoringError = error.localizedDescription
            print("[ScreenTimeService] Monitoring failed: \(error)")
        }
    }

    @MainActor
    func syncLatestData(modelContext: ModelContext) {
        ScreenTimeDataSyncService.shared.syncLatestDailyData(into: modelContext)
    }
}
