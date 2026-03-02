import SwiftUI

extension Color {
    static let glassBackground = Color(.systemBackground)
    static let productive = Color.green
    static let neutral = Color.orange
    static let mindless = Color.red
    static let primaryAccent = Color.blue
    static let secondaryAccent = Color.purple
    
    static func scoreColor(for score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 40 { return .orange }
        return .red
    }
    
    static func scoreGradient(for score: Int) -> LinearGradient {
        if score >= 80 {
            return LinearGradient(colors: [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.19, green: 0.82, blue: 0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if score >= 40 {
            return LinearGradient(colors: [.orange, Color(red: 1, green: 0.84, blue: 0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [.red, Color(red: 1, green: 0.39, blue: 0.51)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static let moodAmazing = Color(red: 1, green: 0.84, blue: 0.04)
    static let moodGood = Color.green
    static let moodOkay = Color.orange
    static let moodMeh = Color(red: 0.8, green: 0.5, blue: 0)
    static let moodBad = Color.red
    static let moodAwful = Color.purple
}
