import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    func registerCategories() {
        let takeBreak = UNNotificationAction(identifier: "TAKE_BREAK", title: "Take a Break", options: [])
        let keepGoing = UNNotificationAction(identifier: "KEEP_GOING", title: "Keep Going", options: [])
        let snooze = UNNotificationAction(identifier: "SNOOZE", title: "Remind in 10 min", options: [])
        let noted = UNNotificationAction(identifier: "NOTED", title: "I'm aware", options: [])
        let windDown = UNNotificationAction(identifier: "WIND_DOWN", title: "Wind Down Mode", options: [])
        let fiveMore = UNNotificationAction(identifier: "FIVE_MORE", title: "5 more min", options: [])
        let seeDetails = UNNotificationAction(identifier: "SEE_DETAILS", title: "See Details", options: .foreground)
        
        let gentleCategory = UNNotificationCategory(identifier: "GENTLE_REMINDER", actions: [takeBreak, keepGoing], intentIdentifiers: [])
        let longSessionCategory = UNNotificationCategory(identifier: "LONG_SESSION", actions: [snooze, noted], intentIdentifiers: [])
        let bedtimeCategory = UNNotificationCategory(identifier: "BEDTIME_NUDGE", actions: [windDown, fiveMore], intentIdentifiers: [])
        let morningCategory = UNNotificationCategory(identifier: "MORNING_SUMMARY", actions: [seeDetails], intentIdentifiers: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([gentleCategory, longSessionCategory, bedtimeCategory, morningCategory])
    }
    
    func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
