import Foundation
import SwiftData

final class GoalTracker {
    static let shared = GoalTracker()

    /// Tracks the last date a streak was evaluated per goal ID to avoid
    /// incrementing streaks multiple times on the same day.
    private var lastStreakEvaluationDate: [UUID: Date] = [:]

    func updateGoalProgress(goal: UserGoal, report: DailyReport) {
        let reportDay = Calendar.current.startOfDay(for: report.date)

        switch goal.type {
        case .reduceTotal:
            let totalMinutes = report.totalScreenTime / 60.0
            goal.currentValue = totalMinutes
            updateStreak(for: goal, met: totalMinutes <= goal.targetValue, on: reportDay)

        case .reduceApp:
            if let appName = goal.relatedAppName {
                let normalizedGoalApp = appName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                let matchedApp = report.topApps.first { entry in
                    let entryName = entry.appName
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    let entryId = entry.appIdentifier
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()

                    // 1. Exact match on name or identifier
                    if entryName == normalizedGoalApp || entryId == normalizedGoalApp {
                        return true
                    }

                    // 2. Name contains (either direction, both ≥ 3 chars)
                    if normalizedGoalApp.count >= 3 && entryName.count >= 3 {
                        if entryName.contains(normalizedGoalApp) || normalizedGoalApp.contains(entryName) {
                            return true
                        }
                    }

                    // 3. Full identifier contains the goal app name
                    if normalizedGoalApp.count >= 4 && entryId.contains(normalizedGoalApp) {
                        return true
                    }

                    // 4. Match against identifier segments (e.g., "ph.telegra.Telegraph")
                    let segments = entryId.split(separator: ".").map { String($0).lowercased() }
                    for seg in segments where seg.count >= 4 && normalizedGoalApp.count >= 4 {
                        if normalizedGoalApp.contains(seg) || seg.contains(normalizedGoalApp) {
                            return true
                        }
                    }

                    return false
                }
                let appTime = matchedApp?.duration ?? 0
                goal.currentValue = appTime / 60.0
                updateStreak(for: goal, met: goal.currentValue <= goal.targetValue, on: reportDay)
            }

        case .increaseProductive:
            let totalTime = report.totalScreenTime
            guard totalTime > 0 else { return }
            let productivePercentage = (report.productiveTime / totalTime) * 100
            goal.currentValue = productivePercentage
            updateStreak(for: goal, met: productivePercentage >= goal.targetValue, on: reportDay)

        case .reducePickups:
            let totalPickups = report.topApps.reduce(0) { $0 + $1.pickupCount }
            goal.currentValue = Double(totalPickups)
            updateStreak(for: goal, met: Double(totalPickups) <= goal.targetValue, on: reportDay)

        case .noPhoneAfter, .mindfulBreaks, .moodCheck:
            break
        }
    }

    func isGoalMet(_ goal: UserGoal) -> Bool {
        switch goal.type {
        case .reduceTotal, .reducePickups:
            // No data tracked yet → not met
            guard goal.currentValue > 0 || goal.streak > 0 else { return false }
            return goal.currentValue <= goal.targetValue
        case .reduceApp:
            // 0 usage is valid "met" only if goal was evaluated (streak > 0)
            guard goal.currentValue > 0 || goal.streak > 0 else { return false }
            return goal.currentValue <= goal.targetValue
        case .increaseProductive:
            return goal.currentValue >= goal.targetValue
        case .moodCheck:
            return goal.currentValue >= goal.targetValue
        case .noPhoneAfter, .mindfulBreaks:
            // Manual tracking goals — cannot auto-determine
            return false
        }
    }

    func remainingForGoal(_ goal: UserGoal) -> Double {
        switch goal.type {
        case .reduceTotal, .reduceApp, .reducePickups:
            return max(0, goal.targetValue - goal.currentValue)
        case .increaseProductive:
            return max(0, goal.targetValue - goal.currentValue)
        case .moodCheck, .mindfulBreaks:
            return max(0, goal.targetValue - goal.currentValue)
        case .noPhoneAfter:
            // Bedtime boundary — not a quantity-based remaining
            return 0
        }
    }

    /// Updates goal progress directly from shared extension data,
    /// bypassing the DailyReport/sync pipeline for immediate freshness.
    func updateGoalFromSharedData(goal: UserGoal, sharedData: SharedDailyData) {
        let reportDay = Calendar.current.startOfDay(for: sharedData.date)

        switch goal.type {
        case .reduceTotal:
            let totalMinutes = sharedData.totalScreenTime / 60.0
            goal.currentValue = totalMinutes
            updateStreak(for: goal, met: totalMinutes <= goal.targetValue, on: reportDay)

        case .reduceApp:
            if let appName = goal.relatedAppName {
                let normalizedGoalApp = appName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                let matchedApp = sharedData.appUsages.first { usage in
                    let entryName = usage.appName
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    let entryId = usage.appIdentifier
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()

                    if entryName == normalizedGoalApp || entryId == normalizedGoalApp { return true }
                    if normalizedGoalApp.count >= 3 && entryName.count >= 3 {
                        if entryName.contains(normalizedGoalApp) || normalizedGoalApp.contains(entryName) { return true }
                    }
                    if normalizedGoalApp.count >= 4 && entryId.contains(normalizedGoalApp) { return true }
                    let segments = entryId.split(separator: ".").map { String($0).lowercased() }
                    for seg in segments where seg.count >= 4 && normalizedGoalApp.count >= 4 {
                        if normalizedGoalApp.contains(seg) || seg.contains(normalizedGoalApp) { return true }
                    }
                    return false
                }
                let appTime = matchedApp?.duration ?? 0
                goal.currentValue = appTime / 60.0
                updateStreak(for: goal, met: goal.currentValue <= goal.targetValue, on: reportDay)
            }

        case .reducePickups:
            let totalPickups = sharedData.appUsages.reduce(0) { $0 + $1.pickupCount }
            goal.currentValue = Double(totalPickups)
            updateStreak(for: goal, met: Double(totalPickups) <= goal.targetValue, on: reportDay)

        case .increaseProductive:
            // Requires classification engine which is only available via DailyReport
            break

        case .noPhoneAfter, .mindfulBreaks, .moodCheck:
            break
        }
    }

    /// Updates mood check goal based on whether a mood entry exists for today.
    func updateMoodCheckGoal(_ goal: UserGoal, hasMoodEntryToday: Bool) {
        guard goal.type == .moodCheck else { return }
        let today = Calendar.current.startOfDay(for: Date())
        goal.currentValue = hasMoodEntryToday ? 1 : 0
        updateStreak(for: goal, met: hasMoodEntryToday, on: today)
    }

    private func updateStreak(for goal: UserGoal, met: Bool, on reportDay: Date) {
        let lastEvalDay = lastStreakEvaluationDate[goal.id]

        if lastEvalDay == reportDay {
            // Already evaluated for this day — only update if the goal
            // was previously met but is now broken (value exceeded mid-day).
            if !met {
                goal.streak = 0
            }
            return
        }

        // First evaluation for this report day.
        lastStreakEvaluationDate[goal.id] = reportDay

        if met {
            goal.streak += 1
            goal.bestStreak = max(goal.bestStreak, goal.streak)
        } else {
            goal.streak = 0
        }
    }
}
