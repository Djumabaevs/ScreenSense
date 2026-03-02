import Foundation
import SwiftData

final class GoalTracker {
    static let shared = GoalTracker()
    
    func updateGoalProgress(goal: UserGoal, report: DailyReport) {
        switch goal.type {
        case .reduceTotal:
            let totalMinutes = report.totalScreenTime / 60.0
            goal.currentValue = totalMinutes
            if totalMinutes <= goal.targetValue {
                goal.streak += 1
                goal.bestStreak = max(goal.bestStreak, goal.streak)
            } else {
                goal.streak = 0
            }
            
        case .reduceApp:
            if let appName = goal.relatedAppName {
                let appTime = report.topApps.first { $0.appName == appName }?.duration ?? 0
                goal.currentValue = appTime / 60.0
                if goal.currentValue <= goal.targetValue {
                    goal.streak += 1
                    goal.bestStreak = max(goal.bestStreak, goal.streak)
                } else {
                    goal.streak = 0
                }
            }
            
        case .increaseProductive:
            let totalTime = report.totalScreenTime
            guard totalTime > 0 else { return }
            let productivePercentage = (report.productiveTime / totalTime) * 100
            goal.currentValue = productivePercentage
            if productivePercentage >= goal.targetValue {
                goal.streak += 1
                goal.bestStreak = max(goal.bestStreak, goal.streak)
            } else {
                goal.streak = 0
            }
            
        case .reducePickups:
            let totalPickups = report.topApps.reduce(0) { $0 + $1.pickupCount }
            goal.currentValue = Double(totalPickups)
            if Double(totalPickups) <= goal.targetValue {
                goal.streak += 1
                goal.bestStreak = max(goal.bestStreak, goal.streak)
            } else {
                goal.streak = 0
            }
            
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
}
