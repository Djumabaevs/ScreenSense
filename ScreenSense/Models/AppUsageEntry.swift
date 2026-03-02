import Foundation
import SwiftData

@Model
final class AppUsageEntry {
    var appIdentifier: String
    var appName: String
    var categoryRaw: String
    var duration: TimeInterval
    var pickupCount: Int
    var longestSession: TimeInterval
    var contentQualityRaw: String
    var emotionalImpactRaw: String
    var date: Date
    var report: DailyReport?
    
    var category: AppCategory {
        get { AppCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    var contentQuality: ContentQuality {
        get { ContentQuality(rawValue: contentQualityRaw) ?? .neutral }
        set { contentQualityRaw = newValue.rawValue }
    }
    
    var emotionalImpact: EmotionalImpact {
        get { EmotionalImpact(rawValue: emotionalImpactRaw) ?? .neutral }
        set { emotionalImpactRaw = newValue.rawValue }
    }
    
    init(appIdentifier: String = "", appName: String = "", category: AppCategory = .other, duration: TimeInterval = 0, pickupCount: Int = 0, longestSession: TimeInterval = 0, contentQuality: ContentQuality = .neutral, emotionalImpact: EmotionalImpact = .neutral, date: Date = .now) {
        self.appIdentifier = appIdentifier
        self.appName = appName
        self.categoryRaw = category.rawValue
        self.duration = duration
        self.pickupCount = pickupCount
        self.longestSession = longestSession
        self.contentQualityRaw = contentQuality.rawValue
        self.emotionalImpactRaw = emotionalImpact.rawValue
        self.date = date
    }
}
