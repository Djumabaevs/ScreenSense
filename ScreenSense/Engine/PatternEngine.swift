import Foundation

enum UsagePattern: String {
    case doomScrolling
    case bingeWatching
    case lateNight
    case morningScroll
    case procrastination
    case boredomCycle
    case focusedWork
    
    var displayName: String {
        switch self {
        case .doomScrolling: return "Doom Scrolling"
        case .bingeWatching: return "Binge Watching"
        case .lateNight: return "Late Night Usage"
        case .morningScroll: return "Morning Scroll"
        case .procrastination: return "Procrastination"
        case .boredomCycle: return "Boredom Cycle"
        case .focusedWork: return "Focused Work"
        }
    }
    
    var isNegative: Bool {
        switch self {
        case .focusedWork: return false
        default: return true
        }
    }
}

final class PatternEngine {
    static let shared = PatternEngine()
    
    func detectPatterns(entries: [AppUsageEntry], hour: Int) -> [UsagePattern] {
        var patterns: [UsagePattern] = []
        
        let socialEntries = entries.filter { $0.category == .social || $0.category == .news }
        if socialEntries.count >= 3 {
            let totalSocialTime = socialEntries.reduce(0.0) { $0 + $1.duration }
            if totalSocialTime > 1200 {
                patterns.append(.doomScrolling)
            }
        }
        
        let entertainmentEntries = entries.filter { $0.category == .entertainment }
        let totalEntertainmentTime = entertainmentEntries.reduce(0.0) { $0 + $1.duration }
        if totalEntertainmentTime > 7200 {
            patterns.append(.bingeWatching)
        }
        
        if hour >= 23 || hour <= 5 {
            let activeEntries = entries.filter { $0.duration > 300 }
            if !activeEntries.isEmpty {
                patterns.append(.lateNight)
            }
        }
        
        if hour >= 6 && hour <= 8 {
            let socialFirst = entries.first { $0.category == .social }
            if socialFirst != nil {
                patterns.append(.morningScroll)
            }
        }
        
        let productiveEntries = entries.filter { $0.contentQuality == .productive }
        let longestProductive = productiveEntries.max(by: { $0.longestSession < $1.longestSession })
        if let longest = longestProductive, longest.longestSession > 1800 {
            patterns.append(.focusedWork)
        }
        
        let shortSessions = entries.filter { $0.duration < 120 }
        if shortSessions.count >= 10 {
            patterns.append(.boredomCycle)
        }
        
        return patterns
    }
}
