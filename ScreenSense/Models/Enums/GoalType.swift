import Foundation

enum GoalType: String, Codable, CaseIterable {
    case reduceTotal
    case reduceApp
    case increaseProductive
    case reducePickups
    case noPhoneAfter
    case mindfulBreaks
    case moodCheck
    
    var displayName: String {
        switch self {
        case .reduceTotal: return "Reduce Screen Time"
        case .reduceApp: return "Limit Specific App"
        case .increaseProductive: return "More Productive Time"
        case .reducePickups: return "Fewer Pickups"
        case .noPhoneAfter: return "Bedtime Boundary"
        case .mindfulBreaks: return "Mindful Breaks"
        case .moodCheck: return "Daily Mood Check"
        }
    }
    
    var icon: String {
        switch self {
        case .reduceTotal: return "hourglass"
        case .reduceApp: return "iphone"
        case .increaseProductive: return "checkmark.circle"
        case .reducePickups: return "hand.raised"
        case .noPhoneAfter: return "moon.fill"
        case .mindfulBreaks: return "pause.circle"
        case .moodCheck: return "face.smiling"
        }
    }
}

enum GoalUnit: String, Codable {
    case minutes
    case hours
    case percentage
    case count
    case time
}

enum GoalFrequency: String, Codable {
    case daily
    case weekly
}
