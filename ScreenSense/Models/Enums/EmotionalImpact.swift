import Foundation

enum EmotionalImpact: String, Codable, CaseIterable {
    case positive
    case neutral
    case negative
    case anxious
    case fomo
    
    var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        case .anxious: return "Anxious"
        case .fomo: return "FOMO"
        }
    }
    
    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .neutral: return "😐"
        case .negative: return "😔"
        case .anxious: return "😰"
        case .fomo: return "😳"
        }
    }
}
