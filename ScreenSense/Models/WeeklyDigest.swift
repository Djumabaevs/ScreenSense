import Foundation
import SwiftData

@Model
final class WeeklyDigest {
    var weekStart: Date
    var weekEnd: Date
    var averageScore: Int
    var totalScreenTime: TimeInterval
    var productivePercentage: Float
    var topInsight: String
    var moodTrendRaw: String
    var comparedToLastWeek: Float
    
    var moodTrend: MoodTrend {
        get { MoodTrend(rawValue: moodTrendRaw) ?? .stable }
        set { moodTrendRaw = newValue.rawValue }
    }
    
    init(weekStart: Date = .now, weekEnd: Date = .now, averageScore: Int = 0, totalScreenTime: TimeInterval = 0, productivePercentage: Float = 0, topInsight: String = "", moodTrend: MoodTrend = .stable, comparedToLastWeek: Float = 0) {
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.averageScore = averageScore
        self.totalScreenTime = totalScreenTime
        self.productivePercentage = productivePercentage
        self.topInsight = topInsight
        self.moodTrendRaw = moodTrend.rawValue
        self.comparedToLastWeek = comparedToLastWeek
    }
}
