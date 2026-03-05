import Foundation
import UserNotifications

final class NudgeScheduler {
    static let shared = NudgeScheduler()

    // MARK: - Gentle Reminder (80% of goal)

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

    // MARK: - Bedtime Nudge

    func scheduleBedtimeNudge(bedtimeHour: Int) {
        // Remove previous bedtime nudge before scheduling new one
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bedtime_nudge"])

        let content = UNMutableNotificationContent()
        content.title = "Time to Wind Down"
        content.body = "It's past your bedtime goal. Blue light from your screen can affect your sleep quality. Sweet dreams!"
        content.sound = .default
        content.categoryIdentifier = "BEDTIME_NUDGE"

        var dateComponents = DateComponents()
        dateComponents.hour = bedtimeHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "bedtime_nudge", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Morning Summary

    func scheduleMorningSummary(hour: Int, score: Int, totalTime: TimeInterval) {
        // Remove previous morning summary before scheduling new one
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morning_summary"])

        let content = UNMutableNotificationContent()
        if score > 0 {
            content.title = "Yesterday's Score: \(score)"
            content.body = "Total: \(formatTime(totalTime)). Tap to see your detailed report."
        } else {
            content.title = "Good Morning!"
            content.body = "Check your daily report and set today's focus."
        }
        content.sound = .default
        content.categoryIdentifier = "MORNING_SUMMARY"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_summary", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Goal Streak Broken

    func scheduleStreakBrokenNotification(goalName: String, streakDays: Int) {
        let alertEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.alertOnStreakBroken) as? Bool ?? true
        guard alertEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Streak Ended"
        content.body = "Your \(streakDays)-day \(goalName) streak has ended. Start a new one today!"
        content.sound = .default
        content.categoryIdentifier = "GENTLE_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_broken_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Achievement Earned

    func scheduleAchievementNotification(title: String) {
        let alertEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.alertOnAchievementEarned) as? Bool ?? true
        guard alertEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! 🎉"
        content.body = "You've earned \"\(title)\". Keep up the great work!"
        content.sound = .default
        content.categoryIdentifier = "MORNING_SUMMARY"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
