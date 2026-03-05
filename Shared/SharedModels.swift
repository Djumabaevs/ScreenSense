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

struct SharedAppUsage: Codable, Hashable, Identifiable {
    var id: String { appIdentifier }
    var appIdentifier: String
    var appName: String
    var category: String
    var duration: TimeInterval
    var pickupCount: Int
}

// MARK: - Goal Definitions (Main App → Extension)

/// Lightweight goal definition that the main app writes to shared storage
/// so the extension can read it and compute goal progress directly.
struct SharedGoalDefinition: Codable {
    var id: String
    var typeRaw: String
    var targetValue: Double
    var relatedAppName: String?
    var currentStreak: Int
    var bestStreak: Int
}

// MARK: - Goal Results (Extension → Main App)

/// Goal progress computed by the extension, written to shared storage
/// for the main app to read and apply to UserGoal objects.
struct SharedGoalResult: Codable {
    var goalId: String
    var currentValue: Double
    var isMet: Bool
    var date: Date
}
