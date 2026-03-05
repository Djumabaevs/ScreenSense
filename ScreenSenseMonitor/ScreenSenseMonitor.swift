import DeviceActivity
import Foundation
import UserNotifications

class ScreenSenseMonitor: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        persistMonitorEvent("intervalStarted:\(activity.rawValue)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        persistMonitorEvent("intervalEnded:\(activity.rawValue)")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        persistMonitorEvent("thresholdReached:\(event.rawValue)")

        // Parse the event name to determine which goal and level triggered
        let eventRaw = event.rawValue
        if eventRaw.contains(".80") {
            // 80% warning — approaching limit
            scheduleWarningNotification(eventName: eventRaw)
        } else if eventRaw.contains(".100") {
            // 100% — limit reached
            scheduleLimitReachedNotification(eventName: eventRaw)
        } else {
            // Fallback threshold (generic 2h)
            scheduleFallbackNotification()
        }
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        persistMonitorEvent("intervalWillStartWarning:\(activity.rawValue)")
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        persistMonitorEvent("intervalWillEndWarning:\(activity.rawValue)")
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        persistMonitorEvent("thresholdWarning:\(event.rawValue)")
    }

    // MARK: - Event Persistence

    private func persistMonitorEvent(_ value: String) {
        let appGroup = AppGroupManager.shared
        appGroup.save(value, forKey: UserDefaultsKeys.monitorLastEvent)
        appGroup.save(Date(), forKey: UserDefaultsKeys.monitorLastEventDate)
    }

    // MARK: - Goal-Aware Notifications

    /// 80% warning: "You're approaching your [goal] limit"
    private func scheduleWarningNotification(eventName: String) {
        let goalInfo = resolveGoalInfo(from: eventName)

        let content = UNMutableNotificationContent()
        content.title = "Approaching Limit"
        content.body = "You've used 80% of your \(goalInfo.label) goal. \(goalInfo.detail)"
        content.sound = .default
        content.categoryIdentifier = "GENTLE_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "goal-warning-\(eventName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// 100% reached: "You've hit your [goal] limit"
    private func scheduleLimitReachedNotification(eventName: String) {
        let goalInfo = resolveGoalInfo(from: eventName)

        let content = UNMutableNotificationContent()
        content.title = "\(goalInfo.label) Limit Reached"
        content.body = "You've reached your \(goalInfo.detail). Time for a break?"
        content.sound = .default
        content.categoryIdentifier = "LONG_SESSION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "goal-limit-\(eventName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Fallback for generic 2-hour threshold
    private func scheduleFallbackNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ScreenSense Check-In"
        content.body = "You've been using your phone for 2 hours today. A short break helps your focus."
        content.sound = .default
        content.categoryIdentifier = "LONG_SESSION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "screensense-threshold-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Goal Resolution

    private struct GoalInfo {
        var label: String  // e.g., "Screen Time" or "YouTube"
        var detail: String // e.g., "120 minute daily limit" or "15 min YouTube limit"
    }

    /// Parses event name like "goal.reduceTotal.UUID.80" and resolves to human-readable info
    private func resolveGoalInfo(from eventName: String) -> GoalInfo {
        let parts = eventName.split(separator: ".")
        // Expected format: goal.<type>.<id>.<level>
        guard parts.count >= 3 else {
            return GoalInfo(label: "Screen Time", detail: "daily screen time goal")
        }

        let goalType = String(parts[1])
        let goalId = parts.count >= 4 ? String(parts[2]) : ""

        // Try to find the matching goal definition for more detail
        let goalDefs = loadGoalDefinitions()
        let matchingDef = goalDefs.first { $0.id == goalId }

        switch goalType {
        case "reduceTotal":
            let target = matchingDef.map { "\(Int($0.targetValue)) minute" } ?? "daily"
            return GoalInfo(label: "Screen Time", detail: "\(target) daily limit")
        case "reduceApp":
            let appName = matchingDef?.relatedAppName ?? "app"
            let target = matchingDef.map { "\(Int($0.targetValue)) min" } ?? ""
            return GoalInfo(label: appName, detail: "\(target) \(appName) limit")
        default:
            return GoalInfo(label: "Screen Time", detail: "daily screen time goal")
        }
    }

    // MARK: - Data Loading (Monitor CAN read from shared container)

    private func loadGoalDefinitions() -> [SharedGoalDefinition] {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
            let fileURL = containerURL.appendingPathComponent("goal_definitions.json")
            if let data = try? Data(contentsOf: fileURL),
               let defs = try? JSONDecoder().decode([SharedGoalDefinition].self, from: data) {
                return defs
            }
        }

        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            defaults.synchronize()
            if let data = defaults.data(forKey: "goalDefinitions"),
               let defs = try? JSONDecoder().decode([SharedGoalDefinition].self, from: data) {
                return defs
            }
        }

        return []
    }
}
