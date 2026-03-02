import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static let sampleReport: DailyReport = {
        let report = DailyReport(
            date: .now,
            totalScreenTime: 12240,
            productiveTime: 4320,
            neutralTime: 3720,
            mindlessTime: 4200,
            score: 78
        )
        return report
    }()
    
    static let sampleApps: [AppUsageEntry] = [
        AppUsageEntry(appIdentifier: "instagram", appName: "Instagram", category: .social, duration: 3120, pickupCount: 12, longestSession: 840, contentQuality: .mindless, emotionalImpact: .negative),
        AppUsageEntry(appIdentifier: "youtube", appName: "YouTube", category: .entertainment, duration: 2280, pickupCount: 5, longestSession: 1200, contentQuality: .neutral, emotionalImpact: .neutral),
        AppUsageEntry(appIdentifier: "notion", appName: "Notion", category: .productivity, duration: 1320, pickupCount: 3, longestSession: 900, contentQuality: .productive, emotionalImpact: .positive),
        AppUsageEntry(appIdentifier: "tiktok", appName: "TikTok", category: .social, duration: 1080, pickupCount: 8, longestSession: 600, contentQuality: .mindless, emotionalImpact: .negative),
        AppUsageEntry(appIdentifier: "telegram", appName: "Telegram", category: .messaging, duration: 840, pickupCount: 15, longestSession: 300, contentQuality: .neutral, emotionalImpact: .neutral),
    ]
    
    static let sampleInsights: [Insight] = [
        Insight(type: .lateNightUsage, title: "Night Owl Alert", body: "You used your phone for 47 minutes after your bedtime yesterday. That's 23 min more than your weekly average.", severity: .important, actionable: true, suggestedAction: "Try setting a bedtime reminder at 23:00"),
        Insight(type: .improvementTrend, title: "Positive Trend!", body: "Your productive time increased by 23% this week! Notion and Xcode are your top productive apps.", severity: .info, actionable: false),
        Insight(type: .doomScrolling, title: "Doom-Scrolling Detected", body: "You switched between Instagram and TikTok 14 times today. This pattern suggests seeking stimulation.", severity: .gentle, actionable: true, suggestedAction: "Try a 5-minute mindful break instead of switching apps"),
    ]
    
    static let sampleGoals: [UserGoal] = [
        {
            let g = UserGoal(type: .reduceTotal, targetValue: 180, currentValue: 134, unit: .minutes, frequency: .daily, streak: 5, bestStreak: 7)
            return g
        }(),
        {
            let g = UserGoal(type: .reduceApp, targetValue: 30, currentValue: 22, unit: .minutes, frequency: .daily, streak: 2, bestStreak: 4, relatedAppName: "Instagram")
            return g
        }(),
        {
            let g = UserGoal(type: .noPhoneAfter, targetValue: 23, currentValue: 23, unit: .time, frequency: .daily, streak: 7, bestStreak: 7)
            return g
        }(),
        {
            let g = UserGoal(type: .increaseProductive, targetValue: 50, currentValue: 38, unit: .percentage, frequency: .daily, streak: 0, bestStreak: 3)
            return g
        }(),
    ]
    
    static let sampleMoodEntries: [MoodEntry] = [
        MoodEntry(mood: 0.8, moodLabel: .good, context: "Productive morning", linkedApps: ["Notion", "Xcode"]),
        MoodEntry(date: Date().daysAgo(1), mood: 0.6, moodLabel: .okay, context: "Scrolled too much", linkedApps: ["Instagram", "TikTok"]),
        MoodEntry(date: Date().daysAgo(2), mood: 0.4, moodLabel: .meh, context: "Doom scrolling session", linkedApps: ["Twitter", "Reddit"]),
    ]
    
    static let sampleWeeklyDigest: WeeklyDigest = {
        WeeklyDigest(
            weekStart: Date().daysAgo(7),
            weekEnd: .now,
            averageScore: 72,
            totalScreenTime: 80040,
            productivePercentage: 38,
            topInsight: "Your mindless scrolling dropped by 18%!",
            moodTrend: .improving,
            comparedToLastWeek: 12
        )
    }()
}
