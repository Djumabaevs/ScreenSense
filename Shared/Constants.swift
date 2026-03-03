import Foundation

enum AppConstants {
    static let appGroupID = "group.com.screensense.shared"
    static let defaultBedtimeHour = 23
    static let defaultWakeupHour = 7
    static let maxDailyInsights = 5
    static let historyDays = 365
}

enum UserDefaultsKeys {
    static let onboardingCompleted = "onboardingCompleted"
    static let selectedTheme = "selectedTheme"
    static let notificationsEnabled = "notificationsEnabled"
    static let nudgeFrequency = "nudgeFrequency"
    static let bedtimeHour = "bedtimeHour"
    static let wakeupHour = "wakeupHour"
    static let hapticEnabled = "hapticEnabled"
    static let animationsEnabled = "animationsEnabled"
    static let nudgeStyle = "nudgeStyle"
    static let accentColorName = "accentColorName"
    static let morningSummaryEnabled = "morningSummaryEnabled"
    static let eveningDigestEnabled = "eveningDigestEnabled"
    static let weeklyDigestEnabled = "weeklyDigestEnabled"
    static let alertAtEightyPercent = "alertAtEightyPercent"
    static let alertAtOneHundredPercent = "alertAtOneHundredPercent"
    static let alertOnStreakBroken = "alertOnStreakBroken"
    static let alertOnAchievementEarned = "alertOnAchievementEarned"
    static let sharedLatestDailyData = "sharedLatestDailyData"
    static let sharedLatestDailyDataUpdatedAt = "sharedLatestDailyDataUpdatedAt"
    static let sharedLastImportedDataUpdatedAt = "sharedLastImportedDataUpdatedAt"
    static let monitorLastEvent = "monitorLastEvent"
    static let monitorLastEventDate = "monitorLastEventDate"
    static let reportLastGeneratedAt = "reportLastGeneratedAt"
    static let reportLastGeneratedTotalScreenTime = "reportLastGeneratedTotalScreenTime"
    static let reportLastGeneratedAppCount = "reportLastGeneratedAppCount"
    static let installationDate = "installationDate"
}
