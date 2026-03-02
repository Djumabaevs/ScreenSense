import Foundation

final class MoodAnalyzer {
    static let shared = MoodAnalyzer()
    
    func averageMood(entries: [MoodEntry]) -> Float {
        guard !entries.isEmpty else { return 0.5 }
        let total = entries.reduce(Float(0)) { $0 + $1.mood }
        return total / Float(entries.count)
    }
    
    func moodTrend(entries: [MoodEntry]) -> MoodTrend {
        guard entries.count >= 3 else { return .stable }
        
        let recent = entries.prefix(3).map { $0.mood }
        let older = entries.dropFirst(3).prefix(3).map { $0.mood }
        
        guard !older.isEmpty else { return .stable }
        
        let recentAvg = recent.reduce(0, +) / Float(recent.count)
        let olderAvg = older.reduce(0, +) / Float(older.count)
        
        let diff = recentAvg - olderAvg
        if diff > 0.1 { return .improving }
        if diff < -0.1 { return .declining }
        return .stable
    }
    
    func moodScreenTimeCorrelation(moods: [MoodEntry], reports: [DailyReport]) -> String? {
        guard moods.count >= 7, reports.count >= 7 else { return nil }
        
        let highScreenDays = reports.filter { $0.totalScreenTime > 14400 }
        let lowScreenDays = reports.filter { $0.totalScreenTime <= 14400 }
        
        guard !highScreenDays.isEmpty, !lowScreenDays.isEmpty else { return nil }
        
        let highScreenAvgMood = highScreenDays.compactMap { $0.moodAfter }.reduce(0, +) / Float(max(highScreenDays.compactMap { $0.moodAfter }.count, 1))
        let lowScreenAvgMood = lowScreenDays.compactMap { $0.moodAfter }.reduce(0, +) / Float(max(lowScreenDays.compactMap { $0.moodAfter }.count, 1))
        
        if lowScreenAvgMood > highScreenAvgMood + 0.1 {
            let diff = Int((lowScreenAvgMood - highScreenAvgMood) * 100)
            return "On days you use your phone over 4 hours, your mood drops by \(diff)%."
        }
        
        return nil
    }
}
