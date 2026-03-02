import Foundation

final class ClassificationEngine {
    static let shared = ClassificationEngine()
    
    private let defaultClassification: [String: ContentQuality] = [
        "Xcode": .productive, "Notion": .productive, "Obsidian": .productive,
        "Calendar": .productive, "Reminders": .productive, "Notes": .productive,
        "Pages": .productive, "Numbers": .productive, "Keynote": .productive,
        "Slack": .productive, "Linear": .productive, "Figma": .productive,
        "VS Code": .productive, "GitHub": .productive,
        "TikTok": .mindless, "Instagram": .mindless, "Twitter": .mindless,
        "X": .mindless, "Reddit": .mindless, "Facebook": .mindless, "Snapchat": .mindless,
        "YouTube": .neutral, "Safari": .neutral, "Chrome": .neutral,
        "Telegram": .neutral, "WhatsApp": .neutral, "Messages": .neutral,
        "Mail": .neutral, "Maps": .neutral, "Music": .neutral, "Podcasts": .neutral,
        "Duolingo": .productive, "Coursera": .productive, "Udemy": .productive,
    ]
    
    private let categoryDefaults: [AppCategory: ContentQuality] = [
        .productivity: .productive,
        .education: .productive,
        .health: .productive,
        .creativity: .productive,
        .utility: .neutral,
        .messaging: .neutral,
        .finance: .neutral,
        .news: .neutral,
        .shopping: .neutral,
        .social: .mindless,
        .entertainment: .neutral,
    ]
    
    func classify(appName: String, category: AppCategory, duration: TimeInterval, timeOfDay: Int) -> ContentQuality {
        if let known = defaultClassification[appName] {
            if known == .mindless && duration < 600 {
                return .neutral
            }
            return known
        }
        
        if category == .productivity || category == .education {
            return .productive
        }
        
        if category == .social {
            if duration > 600 { return .mindless }
            return .neutral
        }
        
        if category == .entertainment {
            if duration > 1800 { return .mindless }
            return .neutral
        }
        
        if timeOfDay >= 23 || timeOfDay <= 5 {
            if category == .social || category == .entertainment {
                return .mindless
            }
        }
        
        return categoryDefaults[category] ?? .neutral
    }
    
    func classifyEmotionalImpact(quality: ContentQuality, duration: TimeInterval, timeOfDay: Int) -> EmotionalImpact {
        switch quality {
        case .productive:
            return .positive
        case .neutral:
            if duration > 3600 { return .negative }
            return .neutral
        case .mindless:
            if duration > 1200 { return .negative }
            if timeOfDay >= 22 { return .anxious }
            return .neutral
        }
    }
}
