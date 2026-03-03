import Foundation

enum AppCategory: String, Codable, CaseIterable {
    case social
    case messaging
    case entertainment
    case productivity
    case education
    case health
    case news
    case shopping
    case finance
    case creativity
    case utility
    case other
    
    var displayName: String {
        switch self {
        case .social: return "Social"
        case .messaging: return "Messaging"
        case .entertainment: return "Entertainment"
        case .productivity: return "Productivity"
        case .education: return "Education"
        case .health: return "Health"
        case .news: return "News"
        case .shopping: return "Shopping"
        case .finance: return "Finance"
        case .creativity: return "Creativity"
        case .utility: return "Utility"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .social: return "person.2.fill"
        case .messaging: return "message.fill"
        case .entertainment: return "play.circle.fill"
        case .productivity: return "hammer.fill"
        case .education: return "book.fill"
        case .health: return "heart.fill"
        case .news: return "newspaper.fill"
        case .shopping: return "cart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .creativity: return "paintbrush.fill"
        case .utility: return "wrench.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    /// Maps a raw Screen Time category string (e.g. "Social Networking") to an AppCategory.
    static func from(screenTimeCategory raw: String, appName: String = "") -> AppCategory {
        let normalized = raw.lowercased()

        if normalized.contains("social") { return .social }
        if normalized.contains("message") || normalized.contains("communication") { return .messaging }
        if normalized.contains("entertain") || normalized.contains("video") || normalized.contains("game") { return .entertainment }
        if normalized.contains("product") || normalized.contains("business") || normalized.contains("developer") { return .productivity }
        if normalized.contains("education") { return .education }
        if normalized.contains("health") || normalized.contains("fitness") { return .health }
        if normalized.contains("news") { return .news }
        if normalized.contains("shopping") { return .shopping }
        if normalized.contains("finance") { return .finance }
        if normalized.contains("photo") || normalized.contains("graphics") || normalized.contains("creative") { return .creativity }
        if normalized.contains("utility") || normalized.contains("reference") || normalized.contains("navigation") { return .utility }

        let appLower = appName.lowercased()
        if appLower.contains("instagram") || appLower.contains("tiktok") || appLower.contains("reddit") { return .social }
        if appLower.contains("notion") || appLower.contains("calendar") || appLower.contains("xcode") { return .productivity }

        return .other
    }
}
