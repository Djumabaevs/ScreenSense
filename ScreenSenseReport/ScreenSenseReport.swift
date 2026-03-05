import DeviceActivity
import ExtensionKit
import SwiftUI
import Foundation

@main
struct ScreenSenseReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        ScreenSenseTotalActivityReport { summary in
            TotalActivityView(summary: summary)
        }

        ScreenSenseInsightsReport { summary in
            InsightsReportView(summary: summary)
        }

        ScreenSenseGoalProgressReport { summary in
            GoalProgressReportView(summary: summary)
        }
    }
}

// MARK: - Report Contexts

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
    static let insights = Self("insights")
    static let goalProgress = Self("goalProgress")
}

// MARK: - Total Activity Report Scene

struct ScreenSenseTotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (SharedDailyData) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SharedDailyData {
        await processActivityData(data)
    }
}

// MARK: - Insights Report Scene

struct ScreenSenseInsightsReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .insights
    let content: (SharedDailyData) -> InsightsReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SharedDailyData {
        await processActivityData(data)
    }
}

// MARK: - Goal Progress Report Scene

/// A dedicated report scene that processes screen time data specifically for goals.
/// It reads goal definitions from shared storage (written by the main app),
/// computes progress against live screen time data, and renders goal cards directly.
/// This bypasses the extension→app data transfer problem entirely.
struct ScreenSenseGoalProgressReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .goalProgress
    let content: (SharedDailyData) -> GoalProgressReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SharedDailyData {
        await processActivityData(data)
    }
}

// MARK: - Goal Progress Report View (rendered inside the extension)

/// Compact live progress header rendered by the extension.
/// Shows real-time screen time stats and goal progress indicators from Screen Time API data.
/// The host app shows native goal cards below for interactivity (tapping, detail sheets).
struct GoalProgressReportView: View {
    let summary: SharedDailyData

    private var goalDefs: [SharedGoalDefinition] {
        loadGoalDefinitions()
    }

    var body: some View {
        VStack(spacing: 0) {
            if goalDefs.isEmpty {
                // No goals found — show nothing (native cards handle empty state)
                EmptyView()
            } else {
                liveProgressHeader
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Live Progress Header

    private var liveProgressHeader: some View {
        VStack(spacing: 10) {
            // Title row
            HStack {
                Label("Live Progress", systemImage: "circle.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
                Spacer()
                Text(formattedScreenTime)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                Text("today")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Compact goal progress rows
            let screenTimeGoals = goalDefs.filter { isScreenTimeGoal($0.typeRaw) }
            if !screenTimeGoals.isEmpty {
                VStack(spacing: 6) {
                    ForEach(screenTimeGoals, id: \.id) { def in
                        compactGoalRow(for: def)
                    }
                }
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.20), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }

    // MARK: - Compact Goal Row

    private func compactGoalRow(for def: SharedGoalDefinition) -> some View {
        let progress = computeProgress(for: def)

        return HStack(spacing: 8) {
            Image(systemName: iconFor(def.typeRaw))
                .font(.system(size: 11))
                .foregroundStyle(.blue)
                .frame(width: 16)

            Text(compactLabel(for: def))
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)

            Spacer()

            // Compact progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.12))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(progress.isMet ? Color.green : progress.fraction > 0.8 ? Color.orange : Color.blue)
                        .frame(width: max(geo.size.width * min(CGFloat(progress.fraction), 1.0), 2))
                }
            }
            .frame(width: 60, height: 6)

            Text(progress.label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(progress.isMet ? .green : .secondary)
                .frame(width: 80, alignment: .trailing)

            if progress.isMet {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
            }
        }
        .frame(height: 20)
    }

    // MARK: - Helpers

    private var formattedScreenTime: String {
        let totalMin = Int(summary.totalScreenTime / 60)
        let hours = totalMin / 60
        let mins = totalMin % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    private func isScreenTimeGoal(_ typeRaw: String) -> Bool {
        ["reduceTotal", "reduceApp", "increaseProductive", "reducePickups"].contains(typeRaw)
    }

    private func compactLabel(for def: SharedGoalDefinition) -> String {
        switch def.typeRaw {
        case "reduceApp":
            let name = def.relatedAppName ?? "App"
            return "\(name) <\(Int(def.targetValue))m"
        case "reduceTotal":
            return "Screen Time"
        case "increaseProductive":
            return "Productive"
        case "reducePickups":
            return "Pickups"
        default:
            return displayNameFor(def.typeRaw)
        }
    }

    // MARK: - Progress Computation

    private struct GoalProgress {
        var currentValue: Double
        var targetValue: Double
        var fraction: Double
        var isMet: Bool
        var label: String
    }

    private func computeProgress(for def: SharedGoalDefinition) -> GoalProgress {
        switch def.typeRaw {
        case "reduceTotal":
            let totalMin = summary.totalScreenTime / 60.0
            let fraction = def.targetValue > 0 ? totalMin / def.targetValue : 0
            let met = totalMin <= def.targetValue
            return GoalProgress(
                currentValue: totalMin, targetValue: def.targetValue,
                fraction: fraction, isMet: met,
                label: "\(Int(totalMin))m / \(Int(def.targetValue))m"
            )

        case "reduceApp":
            guard let appName = def.relatedAppName else {
                return GoalProgress(currentValue: 0, targetValue: def.targetValue, fraction: 0, isMet: false, label: "0m / \(Int(def.targetValue))m")
            }
            let normalized = appName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matched = summary.appUsages.first { usage in
                let name = usage.appName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let ident = usage.appIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if name == normalized || ident == normalized { return true }
                if normalized.count >= 3 && name.count >= 3 {
                    if name.contains(normalized) || normalized.contains(name) { return true }
                }
                if normalized.count >= 4 && ident.contains(normalized) { return true }
                let segs = ident.split(separator: ".").map { String($0).lowercased() }
                for seg in segs where seg.count >= 4 && normalized.count >= 4 {
                    if normalized.contains(seg) || seg.contains(normalized) { return true }
                }
                return false
            }
            let appMin = (matched?.duration ?? 0) / 60.0
            let fraction = def.targetValue > 0 ? appMin / def.targetValue : 0
            let met = appMin <= def.targetValue
            return GoalProgress(
                currentValue: appMin, targetValue: def.targetValue,
                fraction: fraction, isMet: met,
                label: "\(Int(appMin))m / \(Int(def.targetValue))m"
            )

        case "reducePickups":
            let pickups = Double(summary.pickupCount)
            let fraction = def.targetValue > 0 ? pickups / def.targetValue : 0
            let met = pickups <= def.targetValue
            return GoalProgress(
                currentValue: pickups, targetValue: def.targetValue,
                fraction: fraction, isMet: met,
                label: "\(Int(pickups)) / \(Int(def.targetValue))"
            )

        case "increaseProductive":
            var productive: TimeInterval = 0
            let total = summary.totalScreenTime
            for app in summary.appUsages {
                let cat = app.category.lowercased()
                let nm = app.appName.lowercased()
                if cat.contains("productivity") || cat.contains("education") || cat.contains("developer")
                    || cat.contains("business") || nm.contains("xcode") || nm.contains("slack")
                    || nm.contains("notion") || nm.contains("figma") || nm.contains("calendar")
                    || nm.contains("mail") || nm.contains("notes") || nm.contains("claude") {
                    productive += app.duration
                }
            }
            let pct = total > 0 ? (productive / total) * 100 : 0
            let fraction = def.targetValue > 0 ? pct / def.targetValue : 0
            let met = pct >= def.targetValue
            return GoalProgress(
                currentValue: pct, targetValue: def.targetValue,
                fraction: fraction, isMet: met,
                label: "\(Int(pct))% / \(Int(def.targetValue))%"
            )

        default:
            return GoalProgress(currentValue: 0, targetValue: def.targetValue, fraction: 0, isMet: false, label: "—")
        }
    }

    // MARK: - Display Helpers

    private func iconFor(_ typeRaw: String) -> String {
        switch typeRaw {
        case "reduceTotal": return "hourglass"
        case "reduceApp": return "app.badge.checkmark"
        case "increaseProductive": return "bolt.fill"
        case "reducePickups": return "hand.tap"
        case "noPhoneAfter": return "moon.fill"
        case "mindfulBreaks": return "leaf.fill"
        case "moodCheck": return "face.smiling"
        default: return "target"
        }
    }

    private func displayNameFor(_ typeRaw: String) -> String {
        switch typeRaw {
        case "reduceTotal": return "Screen Time"
        case "reduceApp": return "App Limit"
        case "increaseProductive": return "Productive"
        case "reducePickups": return "Pickups"
        case "noPhoneAfter": return "Bedtime"
        case "mindfulBreaks": return "Breaks"
        case "moodCheck": return "Mood"
        default: return "Goal"
        }
    }

    // MARK: - Data Loading

    private func loadGoalDefinitions() -> [SharedGoalDefinition] {
        // Try file first (written by main app)
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
            let fileURL = containerURL.appendingPathComponent("goal_definitions.json")
            if let data = try? Data(contentsOf: fileURL),
               let defs = try? JSONDecoder().decode([SharedGoalDefinition].self, from: data) {
                return defs
            }
        }

        // Try UserDefaults
        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            defaults.synchronize()
            if let data = defaults.data(forKey: "goalDefinitions"),
               let defs = try? JSONDecoder().decode([SharedGoalDefinition].self, from: data) {
                return defs
            }
        }

        return []
    }
}

// MARK: - Shared Data Processing

private func processActivityData(_ data: DeviceActivityResults<DeviceActivityData>) async -> SharedDailyData {
    struct Aggregate {
        var identifier: String
        var name: String
        var category: String
        var duration: TimeInterval
        var pickups: Int
    }

    var totalScreenTime: TimeInterval = 0
    var totalPickups = 0
    var aggregatedByIdentifier: [String: Aggregate] = [:]

    for await activityData in data {
        for await segment in activityData.activitySegments {
            let segDuration = sanitizedDuration(segment.totalActivityDuration)
            totalScreenTime += segDuration

            for await categoryActivity in segment.categories {
                let categoryName = categoryActivity.category.localizedDisplayName ?? "Other"

                for await applicationActivity in categoryActivity.applications {
                    let identifier = applicationActivity.application.bundleIdentifier
                        ?? applicationActivity.application.localizedDisplayName
                        ?? "unknown.app"
                    let displayName = applicationActivity.application.localizedDisplayName
                        ?? fallbackName(from: identifier)

                    var aggregate = aggregatedByIdentifier[identifier] ?? Aggregate(
                        identifier: identifier,
                        name: displayName,
                        category: categoryName,
                        duration: 0,
                        pickups: 0
                    )

                    aggregate.duration += sanitizedDuration(applicationActivity.totalActivityDuration)
                    aggregate.pickups += applicationActivity.numberOfPickups
                    aggregate.category = categoryName
                    aggregatedByIdentifier[identifier] = aggregate

                    totalPickups += applicationActivity.numberOfPickups
                }
            }
        }
    }

    let appUsages = aggregatedByIdentifier.values
        .map {
            SharedAppUsage(
                appIdentifier: $0.identifier,
                appName: $0.name,
                category: $0.category,
                duration: $0.duration,
                pickupCount: $0.pickups
            )
        }
        .sorted { $0.duration > $1.duration }

    let summary = SharedDailyData(
        date: Calendar.current.startOfDay(for: .now),
        totalScreenTime: totalScreenTime,
        appUsages: appUsages,
        pickupCount: totalPickups,
        generatedAt: .now,
        source: "device-activity-report"
    )

    // Attempt to save to app group (may fail due to ExtensionKit sandbox)
    let appGroup = AppGroupManager.shared
    let savedUD = appGroup.save(summary, forKey: UserDefaultsKeys.sharedLatestDailyData)
    appGroup.save(summary.generatedAt, forKey: UserDefaultsKeys.sharedLatestDailyDataUpdatedAt)
    print("[ReportExt] AppGroup UserDefaults save: \(savedUD ? "✅" : "❌")")

    // Backup: write JSON file to shared container
    if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
        let fileURL = containerURL.appendingPathComponent("latest_daily.json")
        if let encoded = try? JSONEncoder().encode(summary) {
            try? encoded.write(to: fileURL, options: .atomic)
        }
    }

    // Backup: write to Keychain (shared access group, works across app + extension)
    let savedKC = KeychainTransport.save(summary)
    print("[ReportExt] Keychain save: \(savedKC ? "✅" : "❌")")
    print("[ReportExt] Summary: \(Int(summary.totalScreenTime))s, \(summary.appUsages.count) apps, \(summary.pickupCount) pickups")

    return summary
}

private func fallbackName(from identifier: String) -> String {
    let tail = identifier.split(separator: ".").last.map(String.init) ?? identifier
    return tail
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "-", with: " ")
        .capitalized
}

private func sanitizedDuration(_ duration: TimeInterval) -> TimeInterval {
    guard duration.isFinite, duration > 0 else {
        return 0
    }
    return duration
}
