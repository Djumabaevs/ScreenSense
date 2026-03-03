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
                let appTime = report.topApps.first {
                    $0.appName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedGoalApp
                    || $0.appIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedGoalApp
                }?.duration ?? 0
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
        case .reduceTotal, .reduceApp, .reducePickups:
            return goal.currentValue <= goal.targetValue
        case .increaseProductive:
            return goal.currentValue >= goal.targetValue
        case .noPhoneAfter, .mindfulBreaks, .moodCheck:
            return goal.currentValue >= goal.targetValue
        }
    }

    func remainingForGoal(_ goal: UserGoal) -> Double {
        switch goal.type {
        case .reduceTotal, .reduceApp, .reducePickups:
            return max(0, goal.targetValue - goal.currentValue)
        case .increaseProductive:
            return max(0, goal.targetValue - goal.currentValue)
        default:
            return 0
        }
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
