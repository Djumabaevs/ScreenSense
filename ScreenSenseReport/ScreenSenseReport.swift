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
    }
}

// MARK: - Report Contexts

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
    static let insights = Self("insights")
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
    appGroup.save(summary, forKey: UserDefaultsKeys.sharedLatestDailyData)
    appGroup.save(summary.generatedAt, forKey: UserDefaultsKeys.sharedLatestDailyDataUpdatedAt)

    // Backup: write JSON file to shared container
    if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
        let fileURL = containerURL.appendingPathComponent("latest_daily.json")
        if let encoded = try? JSONEncoder().encode(summary) {
            try? encoded.write(to: fileURL, options: .atomic)
        }
    }

    // Backup: write to Keychain (works even if App Group fails)
    KeychainTransport.save(summary)

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
