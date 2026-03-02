import Foundation

enum InsightType: String, Codable, CaseIterable {
    case doomScrolling
    case lateNightUsage
    case pickupHabit
    case longSession
    case moodCorrelation
    case improvementTrend
    case weeklyComparison
    case appSwitch
    case productiveStreak
    case suggestion
    
    var icon: String {
        switch self {
        case .doomScrolling: return "arrow.down.circle.fill"
        case .lateNightUsage: return "moon.fill"
        case .pickupHabit: return "iphone"
        case .longSession: return "clock.fill"
        case .moodCorrelation: return "face.smiling"
        case .improvementTrend: return "chart.line.uptrend.xyaxis"
        case .weeklyComparison: return "calendar"
        case .appSwitch: return "arrow.triangle.2.circlepath"
        case .productiveStreak: return "flame.fill"
        case .suggestion: return "lightbulb.fill"
        }
    }
}

enum InsightSeverity: String, Codable, CaseIterable {
    case info
    case gentle
    case important
    case critical
    
    var displayName: String {
        switch self {
        case .info: return "Info"
        case .gentle: return "Gentle"
        case .important: return "Important"
        case .critical: return "Critical"
        }
    }
    
    var emoji: String {
        switch self {
        case .info: return "ℹ️"
        case .gentle: return "💛"
        case .important: return "🧡"
        case .critical: return "❤️"
        }
    }
}
