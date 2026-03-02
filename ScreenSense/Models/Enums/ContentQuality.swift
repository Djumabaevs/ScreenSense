import SwiftUI

enum ContentQuality: String, Codable, CaseIterable {
    case productive
    case neutral
    case mindless
    
    var displayName: String {
        switch self {
        case .productive: return "Productive"
        case .neutral: return "Neutral"
        case .mindless: return "Mindless"
        }
    }
    
    var color: Color {
        switch self {
        case .productive: return .green
        case .neutral: return .orange
        case .mindless: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .productive: return "checkmark.circle.fill"
        case .neutral: return "minus.circle.fill"
        case .mindless: return "exclamationmark.circle.fill"
        }
    }
    
    var emoji: String {
        switch self {
        case .productive: return "🟢"
        case .neutral: return "🟡"
        case .mindless: return "🔴"
        }
    }
}
