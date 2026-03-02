import Foundation
import SwiftData

@Model
final class DailyReport {
    var date: Date
    var totalScreenTime: TimeInterval
    var productiveTime: TimeInterval
    var neutralTime: TimeInterval
    var mindlessTime: TimeInterval
    var moodBefore: Float?
    var moodAfter: Float?
    @Relationship(deleteRule: .cascade) var topApps: [AppUsageEntry]
    @Relationship(deleteRule: .cascade) var insights: [Insight]
    var score: Int
    
    init(date: Date = .now, totalScreenTime: TimeInterval = 0, productiveTime: TimeInterval = 0, neutralTime: TimeInterval = 0, mindlessTime: TimeInterval = 0, moodBefore: Float? = nil, moodAfter: Float? = nil, topApps: [AppUsageEntry] = [], insights: [Insight] = [], score: Int = 0) {
        self.date = date
        self.totalScreenTime = totalScreenTime
        self.productiveTime = productiveTime
        self.neutralTime = neutralTime
        self.mindlessTime = mindlessTime
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.topApps = topApps
        self.insights = insights
        self.score = score
    }
}
