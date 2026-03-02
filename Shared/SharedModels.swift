import Foundation

struct SharedDailyData: Codable {
    let date: Date
    let totalScreenTime: TimeInterval
    let appUsages: [SharedAppUsage]
    let pickupCount: Int
}

struct SharedAppUsage: Codable {
    let appIdentifier: String
    let appName: String
    let category: String
    let duration: TimeInterval
    let pickupCount: Int
}
