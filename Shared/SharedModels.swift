import Foundation

struct SharedDailyData: Codable {
    var date: Date
    var totalScreenTime: TimeInterval
    var appUsages: [SharedAppUsage]
    var pickupCount: Int
    var generatedAt: Date
    var source: String
    var diagnostics: String?

    init(
        date: Date,
        totalScreenTime: TimeInterval,
        appUsages: [SharedAppUsage],
        pickupCount: Int,
        generatedAt: Date = .now,
        source: String = "unknown",
        diagnostics: String? = nil
    ) {
        self.date = date
        self.totalScreenTime = totalScreenTime
        self.appUsages = appUsages
        self.pickupCount = pickupCount
        self.generatedAt = generatedAt
        self.source = source
        self.diagnostics = diagnostics
    }
}

struct SharedAppUsage: Codable, Hashable {
    var appIdentifier: String
    var appName: String
    var category: String
    var duration: TimeInterval
    var pickupCount: Int
}
