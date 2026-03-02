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
}
