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
        scheduleThresholdNotification()
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

    private func persistMonitorEvent(_ value: String) {
        let appGroup = AppGroupManager.shared
        appGroup.save(value, forKey: UserDefaultsKeys.monitorLastEvent)
        appGroup.save(Date(), forKey: UserDefaultsKeys.monitorLastEventDate)
    }

    private func scheduleThresholdNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ScreenSense Check-In"
        content.body = "You've reached your screen-time threshold. A short break now helps your focus later."
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
}
