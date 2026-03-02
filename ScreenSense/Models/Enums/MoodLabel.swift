import SwiftUI

enum MoodLabel: String, Codable, CaseIterable {
    case amazing
    case good
    case okay
    case meh
    case bad
    case awful
    
    var emoji: String {
        switch self {
        case .amazing: return "🤩"
        case .good: return "😊"
        case .okay: return "😐"
        case .meh: return "😕"
        case .bad: return "😔"
        case .awful: return "😢"
        }
    }
    
    var displayName: String {
        switch self {
        case .amazing: return "Amazing"
        case .good: return "Good"
        case .okay: return "Okay"
        case .meh: return "Meh"
        case .bad: return "Bad"
        case .awful: return "Awful"
        }
    }
    
    var color: Color {
        switch self {
        case .amazing: return Color(red: 1, green: 0.84, blue: 0.04)
        case .good: return .green
        case .okay: return .orange
        case .meh: return Color(red: 0.8, green: 0.5, blue: 0)
        case .bad: return .red
        case .awful: return .purple
        }
    }
    
    var value: Float {
        switch self {
        case .amazing: return 1.0
        case .good: return 0.8
        case .okay: return 0.6
        case .meh: return 0.4
        case .bad: return 0.2
        case .awful: return 0.0
        }
    }
}

enum MoodTrend: String, Codable {
    case improving
    case stable
    case declining
    
    var icon: String {
        switch self {
        case .improving: return "chart.line.uptrend.xyaxis"
        case .stable: return "arrow.right"
        case .declining: return "chart.line.downtrend.xyaxis"
        }
    }
}
