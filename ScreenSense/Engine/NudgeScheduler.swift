import Foundation
import UserNotifications

final class NudgeScheduler {
    static let shared = NudgeScheduler()
    
    func scheduleGentleReminder(currentUsage: TimeInterval, goalLimit: TimeInterval) {
        let percentage = currentUsage / goalLimit
        guard percentage >= 0.8 else { return }
        
        let remaining = Int((goalLimit - currentUsage) / 60)
        
        let content = UNMutableNotificationContent()
        content.title = "ScreenSense"
        content.body = "You've used \(formatTime(currentUsage)) out of your \(formatTime(goalLimit)) goal today. \(remaining) minutes remaining."
        content.sound = .default
        content.categoryIdentifier = "GENTLE_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "gentle_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleBedtimeNudge(bedtimeHour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Wind Down"
        content.body = "It's past your bedtime. Blue light from your screen can affect your sleep quality. Sweet dreams!"
        content.sound = .default
        content.categoryIdentifier = "BEDTIME_NUDGE"
        
        var dateComponents = DateComponents()
        dateComponents.hour = bedtimeHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "bedtime_nudge", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleMorningSummary(hour: Int, score: Int, totalTime: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Yesterday's Score: \(score)"
        content.body = "Total: \(formatTime(totalTime)). Tap to see details."
        content.sound = .default
        content.categoryIdentifier = "MORNING_SUMMARY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_summary", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
