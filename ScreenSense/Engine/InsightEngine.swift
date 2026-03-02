import Foundation

final class InsightEngine {
    static let shared = InsightEngine()
    
    private let templates: [InsightType: [String]] = [
        .doomScrolling: [
            "You switched between social apps %d times in %@. This rapid switching is a classic doom-scrolling pattern.",
            "Detected a doom-scrolling session: %@ of jumping between social apps. Try a 5-minute walk instead.",
        ],
        .lateNightUsage: [
            "You used your phone for %@ after your bedtime. That's %@ than your weekly average.",
            "Late night phone use detected: %@ past your bedtime. Blue light can delay sleep by up to 30 minutes.",
        ],
        .longSession: [
            "You've been on %@ for %@ without a break. Your eyes and posture will thank you for a stretch.",
            "%@ straight on %@! Consider the 20-20-20 rule: every 20 min, look 20 feet away for 20 seconds.",
        ],
        .moodCorrelation: [
            "On days you use your phone over %@, your mood tends to drop. Today you're at %@.",
        ],
        .improvementTrend: [
            "Your %@ improved by %d%% this week! Keep it up!",
            "Great news: you've reduced mindless scrolling by %d%% compared to last week.",
        ],
        .pickupHabit: [
            "You've picked up your phone %d times today — that's every %d minutes on average.",
        ],
        .productiveStreak: [
            "You're on a %d-day productive streak! Your focus is building momentum.",
        ],
    ]
    
    func generateDailyInsights(report: DailyReport, previousReports: [DailyReport]) -> [Insight] {
        var insights: [Insight] = []
        
        let totalMinutes = report.totalScreenTime / 60
        let mindlessMinutes = report.mindlessTime / 60
        
        if mindlessMinutes > 60 {
            let insight = Insight(
                type: .doomScrolling,
                title: "Mindless Scrolling Alert",
                body: "You spent \(Int(mindlessMinutes)) minutes on mindless content today. That's \(Int(mindlessMinutes / totalMinutes * 100))% of your screen time.",
                severity: mindlessMinutes > 120 ? .important : .gentle,
                actionable: true,
                suggestedAction: "Try setting a 30-minute daily limit for social media apps."
            )
            insights.append(insight)
        }
        
        let hour = Calendar.current.component(.hour, from: .now)
        if hour >= 23 || hour <= 2 {
            let insight = Insight(
                type: .lateNightUsage,
                title: "Night Owl Alert",
                body: "You're using your phone late at night. Blue light can affect your sleep quality.",
                severity: .important,
                actionable: true,
                suggestedAction: "Try setting a bedtime reminder and winding down 30 minutes before sleep."
            )
            insights.append(insight)
        }
        
        if !previousReports.isEmpty {
            let lastWeekAvg = previousReports.prefix(7).reduce(0.0) { $0 + $1.productiveTime } / Double(min(previousReports.count, 7))
            if report.productiveTime > lastWeekAvg * 1.2 {
                let improvement = Int(((report.productiveTime - lastWeekAvg) / lastWeekAvg) * 100)
                let insight = Insight(
                    type: .improvementTrend,
                    title: "Positive Trend!",
                    body: "Your productive time increased by \(improvement)% compared to your recent average. Keep it up!",
                    severity: .info,
                    actionable: false
                )
                insights.append(insight)
            }
        }
        
        let pickupCount = report.topApps.reduce(0) { $0 + $1.pickupCount }
        if pickupCount > 80 {
            let avgInterval = Int(totalMinutes / Double(max(pickupCount, 1)))
            let insight = Insight(
                type: .pickupHabit,
                title: "Frequent Pickups",
                body: "You picked up your phone \(pickupCount) times today — that's every \(avgInterval) minutes on average.",
                severity: pickupCount > 120 ? .important : .gentle,
                actionable: true,
                suggestedAction: "Try batching your phone checks to reduce interruptions."
            )
            insights.append(insight)
        }
        
        return Array(insights.prefix(5))
    }
}
