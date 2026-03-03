import Foundation
import SwiftData

@MainActor
final class ScreenTimeDataSyncService {
    static let shared = ScreenTimeDataSyncService()

    private let appGroupManager = AppGroupManager.shared
    private let systemDefaults = UserDefaults.standard
    private let calendar = Calendar.current

    func syncLatestDailyData(into modelContext: ModelContext) {
        var sharedData: SharedDailyData? = appGroupManager.load(forKey: UserDefaultsKeys.sharedLatestDailyData)

        // Fallback: try reading the direct file the extension writes
        if sharedData == nil {
            sharedData = loadDirectFile()
        }

        // Fallback: try keychain transport
        if sharedData == nil {
            if let kcData = KeychainTransport.load() {
                print("[SyncService] Loaded from keychain: \(Int(kcData.totalScreenTime))s, \(kcData.appUsages.count) apps")
                sharedData = kcData
            }
        }

        guard let sharedData else {
            print("[SyncService] No shared data from any source (appGroup: \(appGroupManager.isSharedContainerAvailable))")
            return
        }

        print("[SyncService] Loaded shared data: \(Int(sharedData.totalScreenTime))s, \(sharedData.appUsages.count) apps, generated: \(sharedData.generatedAt)")

        let sharedUpdatedAt: Date = appGroupManager.load(forKey: UserDefaultsKeys.sharedLatestDailyDataUpdatedAt) ?? sharedData.generatedAt
        let lastImportedAt = systemDefaults.object(forKey: UserDefaultsKeys.sharedLastImportedDataUpdatedAt) as? Date

        let maxAllowedImportedAt = Date().addingTimeInterval(3600)
        if let lastImportedAt, lastImportedAt <= maxAllowedImportedAt, lastImportedAt >= sharedUpdatedAt {
            return
        }

        if let lastImportedAt, lastImportedAt > maxAllowedImportedAt {
            print("[SyncService] Resetting corrupted lastImportedAt (future date)")
            systemDefaults.removeObject(forKey: UserDefaultsKeys.sharedLastImportedDataUpdatedAt)
        }

        do {
            let report = try upsertReport(from: sharedData, modelContext: modelContext)
            try updateWeeklyDigest(anchoredAt: report.date, modelContext: modelContext)
            try modelContext.save()
            systemDefaults.set(sharedUpdatedAt, forKey: UserDefaultsKeys.sharedLastImportedDataUpdatedAt)
            print("[SyncService] Sync complete: score=\(report.score), screenTime=\(Int(report.totalScreenTime))s, apps=\(report.topApps.count)")
        } catch {
            print("[SyncService] Sync failed: \(error)")
        }
    }

    private func upsertReport(from sharedData: SharedDailyData, modelContext: ModelContext) throws -> DailyReport {
        let dayStart = calendar.startOfDay(for: sharedData.date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            throw SyncError.invalidDateRange
        }

        let reportDescriptor = FetchDescriptor<DailyReport>(
            predicate: #Predicate<DailyReport> { $0.date >= dayStart && $0.date < dayEnd },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let report: DailyReport
        if let existingReport = try modelContext.fetch(reportDescriptor).first {
            report = existingReport

            for app in report.topApps {
                modelContext.delete(app)
            }
            for insight in report.insights {
                modelContext.delete(insight)
            }
            report.topApps.removeAll()
            report.insights.removeAll()
        } else {
            report = DailyReport(date: dayStart)
            modelContext.insert(report)
        }

        let hour = calendar.component(.hour, from: sharedData.generatedAt)
        let sortedUsages = sharedData.appUsages
            .filter { $0.duration > 0 }
            .sorted { $0.duration > $1.duration }

        var appEntries: [AppUsageEntry] = []
        var productiveTime: TimeInterval = 0
        var neutralTime: TimeInterval = 0
        var mindlessTime: TimeInterval = 0

        for usage in sortedUsages {
            let appName = normalizedAppName(for: usage)
            let category = AppCategory.from(screenTimeCategory: usage.category, appName: appName)
            let quality = ClassificationEngine.shared.classify(
                appName: appName,
                category: category,
                duration: usage.duration,
                timeOfDay: hour
            )
            let emotionalImpact = ClassificationEngine.shared.classifyEmotionalImpact(
                quality: quality,
                duration: usage.duration,
                timeOfDay: hour
            )

            let entry = AppUsageEntry(
                appIdentifier: usage.appIdentifier,
                appName: appName,
                category: category,
                duration: usage.duration,
                pickupCount: usage.pickupCount,
                longestSession: usage.duration,
                contentQuality: quality,
                emotionalImpact: emotionalImpact,
                date: dayStart
            )
            entry.report = report
            modelContext.insert(entry)
            appEntries.append(entry)

            switch quality {
            case .productive:
                productiveTime += usage.duration
            case .neutral:
                neutralTime += usage.duration
            case .mindless:
                mindlessTime += usage.duration
            }
        }

        let aggregateDuration = appEntries.reduce(0.0) { $0 + $1.duration }
        report.date = dayStart
        report.topApps = appEntries
        report.totalScreenTime = max(sharedData.totalScreenTime, aggregateDuration)
        report.productiveTime = productiveTime
        report.neutralTime = neutralTime
        report.mindlessTime = mindlessTime

        let previousReports = try fetchPreviousReports(before: dayStart, modelContext: modelContext)
        let activeGoals = try fetchActiveGoals(modelContext: modelContext)

        for goal in activeGoals {
            GoalTracker.shared.updateGoalProgress(goal: goal, report: report)
        }

        let averagePickups = averagePickups(from: previousReports)
        let completedGoals = activeGoals.filter { GoalTracker.shared.isGoalMet($0) }.count
        let moodImprovement = try latestMoodImprovement(modelContext: modelContext)

        report.score = ScoreEngine.shared.calculateScore(
            totalScreenTime: report.totalScreenTime,
            productiveTime: report.productiveTime,
            neutralTime: report.neutralTime,
            mindlessTime: report.mindlessTime,
            lateNightMinutes: 0,
            pickupCount: sharedData.pickupCount,
            averagePickups: averagePickups,
            goalsCompleted: completedGoals,
            totalGoals: activeGoals.count,
            moodImprovement: moodImprovement
        )

        let insights = InsightEngine.shared.generateDailyInsights(
            report: report,
            previousReports: previousReports
        )

        for insight in insights {
            insight.report = report
            modelContext.insert(insight)
        }
        report.insights = insights

        return report
    }

    private func updateWeeklyDigest(anchoredAt date: Date, modelContext: ModelContext) throws {
        let weekStart = date.startOfWeek
        guard
            let weekEndExclusive = calendar.date(byAdding: .day, value: 7, to: weekStart),
            let weekEnd = calendar.date(byAdding: .second, value: -1, to: weekEndExclusive)
        else {
            throw SyncError.invalidDateRange
        }

        let weeklyReportsDescriptor = FetchDescriptor<DailyReport>(
            predicate: #Predicate<DailyReport> { $0.date >= weekStart && $0.date < weekEndExclusive },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let weeklyReports = try modelContext.fetch(weeklyReportsDescriptor)
        guard !weeklyReports.isEmpty else {
            return
        }

        let digestDescriptor = FetchDescriptor<WeeklyDigest>(
            predicate: #Predicate<WeeklyDigest> { $0.weekStart == weekStart }
        )

        let digest: WeeklyDigest
        if let existing = try modelContext.fetch(digestDescriptor).first {
            digest = existing
        } else {
            digest = WeeklyDigest(weekStart: weekStart, weekEnd: weekEnd)
            modelContext.insert(digest)
        }

        let totalScreenTime = weeklyReports.reduce(0.0) { $0 + $1.totalScreenTime }
        let totalProductive = weeklyReports.reduce(0.0) { $0 + $1.productiveTime }
        let averageScore = weeklyReports.map(\.score).reduce(0, +) / max(weeklyReports.count, 1)
        let productivePercentage = totalScreenTime > 0 ? Float((totalProductive / totalScreenTime) * 100.0) : 0

        let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
        let previousWeekEnd = weekStart
        let previousWeekDescriptor = FetchDescriptor<DailyReport>(
            predicate: #Predicate<DailyReport> { $0.date >= previousWeekStart && $0.date < previousWeekEnd }
        )
        let previousWeekReports = try modelContext.fetch(previousWeekDescriptor)
        let previousWeekTotal = previousWeekReports.reduce(0.0) { $0 + $1.totalScreenTime }

        let comparedToLastWeek: Float
        if previousWeekTotal > 0 {
            comparedToLastWeek = Float(((previousWeekTotal - totalScreenTime) / previousWeekTotal) * 100.0)
        } else {
            comparedToLastWeek = 0
        }

        let topInsight = weeklyReports
            .compactMap { $0.insights.first?.title }
            .first ?? "Keep going — your weekly pattern is forming."

        let moodTrend = try calculateMoodTrend(start: weekStart, end: weekEndExclusive, modelContext: modelContext)

        digest.weekStart = weekStart
        digest.weekEnd = weekEnd
        digest.averageScore = averageScore
        digest.totalScreenTime = totalScreenTime
        digest.productivePercentage = productivePercentage
        digest.topInsight = topInsight
        digest.moodTrend = moodTrend
        digest.comparedToLastWeek = comparedToLastWeek
    }

    private func fetchPreviousReports(before date: Date, modelContext: ModelContext) throws -> [DailyReport] {
        let descriptor = FetchDescriptor<DailyReport>(
            predicate: #Predicate<DailyReport> { $0.date < date },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchActiveGoals(modelContext: ModelContext) throws -> [UserGoal] {
        let descriptor = FetchDescriptor<UserGoal>(
            predicate: #Predicate<UserGoal> { $0.isActive }
        )
        return try modelContext.fetch(descriptor)
    }

    private func latestMoodImprovement(modelContext: ModelContext) throws -> Double {
        let descriptor = FetchDescriptor<MoodEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let moods = try modelContext.fetch(descriptor)
        guard moods.count >= 2 else {
            return 0
        }
        return Double(moods[0].mood - moods[1].mood)
    }

    private func calculateMoodTrend(start: Date, end: Date, modelContext: ModelContext) throws -> MoodTrend {
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate<MoodEntry> { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let moods = try modelContext.fetch(descriptor)

        guard let first = moods.first, let last = moods.last else {
            return .stable
        }

        let delta = last.mood - first.mood
        if delta > 0.15 {
            return .improving
        }
        if delta < -0.15 {
            return .declining
        }
        return .stable
    }

    private func averagePickups(from previousReports: [DailyReport]) -> Int {
        let recentReports = Array(previousReports.prefix(7))
        guard !recentReports.isEmpty else {
            return 70
        }

        let totalPickups = recentReports.reduce(0) { partialResult, report in
            partialResult + report.topApps.reduce(0) { $0 + $1.pickupCount }
        }

        return max(totalPickups / recentReports.count, 1)
    }

    private func loadDirectFile() -> SharedDailyData? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupID
        ) else {
            return nil
        }
        let fileURL = containerURL.appendingPathComponent("latest_daily.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(SharedDailyData.self, from: data)
            print("[SyncService] Loaded from direct file: \(Int(decoded.totalScreenTime))s, \(decoded.appUsages.count) apps")
            return decoded
        } catch {
            print("[SyncService] Direct file decode failed: \(error)")
            return nil
        }
    }

    private func normalizedAppName(for usage: SharedAppUsage) -> String {
        let trimmedName = usage.appName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }

        let identifier = usage.appIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !identifier.isEmpty else {
            return "Unknown App"
        }

        let tail = identifier.split(separator: ".").last.map(String.init) ?? identifier
        return tail
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

enum SyncError: Error {
    case invalidDateRange
}
