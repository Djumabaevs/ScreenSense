import Foundation

final class ScoreEngine {
    static let shared = ScoreEngine()
    
    func calculateScore(
        totalScreenTime: TimeInterval,
        productiveTime: TimeInterval,
        neutralTime: TimeInterval,
        mindlessTime: TimeInterval,
        lateNightMinutes: Double,
        pickupCount: Int,
        averagePickups: Int,
        goalsCompleted: Int,
        totalGoals: Int,
        moodImprovement: Double
    ) -> Int {
        var score: Double = 100.0
        
        let totalMinutes = totalScreenTime / 60.0
        guard totalMinutes > 0 else { return 50 }
        
        let mindlessPercentage = mindlessTime / totalScreenTime
        score -= mindlessPercentage * 40.0
        
        score -= min(lateNightMinutes / 10.0, 15.0)
        
        let excessPickups = max(pickupCount - averagePickups, 0)
        score -= Double(excessPickups) * 0.5
        
        let productivePercentage = productiveTime / totalScreenTime
        score += productivePercentage * 20.0
        
        if totalGoals > 0 {
            let goalCompletion = Double(goalsCompleted) / Double(totalGoals)
            score += goalCompletion * 10.0
        }
        
        score += moodImprovement * 5.0
        
        return Int(max(0, min(100, score)).rounded())
    }
    
    func scoreColor(for score: Int) -> String {
        if score >= 80 { return "green" }
        if score >= 40 { return "orange" }
        return "red"
    }
    
    func scoreLabel(for score: Int) -> String {
        if score >= 80 { return "Great" }
        if score >= 60 { return "Good" }
        if score >= 40 { return "Fair" }
        return "Needs Attention"
    }
}
