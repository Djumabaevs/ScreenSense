import SwiftUI

struct QualityBreakdownView: View {
    let report: DailyReport?
    let sharedData: SharedDailyData?

    private var fallbackClassification: (productive: TimeInterval, neutral: TimeInterval, mindless: TimeInterval)? {
        guard report == nil, let sharedData else {
            return nil
        }

        var productive: TimeInterval = 0
        var neutral: TimeInterval = 0
        var mindless: TimeInterval = 0
        let hour = Calendar.current.component(.hour, from: sharedData.generatedAt)

        for app in sharedData.appUsages where app.duration > 0 && app.duration.isFinite {
            let category = AppCategory.from(screenTimeCategory: app.category, appName: app.appName)
            let quality = ClassificationEngine.shared.classify(
                appName: app.appName,
                category: category,
                duration: app.duration,
                timeOfDay: hour
            )

            switch quality {
            case .productive:
                productive += app.duration
            case .neutral:
                neutral += app.duration
            case .mindless:
                mindless += app.duration
            }
        }

        return (productive, neutral, mindless)
    }
    
    private var totalTime: TimeInterval {
        if let report {
            return max(report.totalScreenTime, 1)
        }
        if let sharedData {
            return max(sharedData.totalScreenTime, 1)
        }
        return 1
    }

    private var productiveTime: TimeInterval {
        report?.productiveTime ?? fallbackClassification?.productive ?? 0
    }

    private var neutralTime: TimeInterval {
        report?.neutralTime ?? fallbackClassification?.neutral ?? 0
    }

    private var mindlessTime: TimeInterval {
        report?.mindlessTime ?? fallbackClassification?.mindless ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            qualityRow(
                label: "Productive",
                time: productiveTime,
                color: .productive,
                emoji: "🟢"
            )
            qualityRow(
                label: "Neutral",
                time: neutralTime,
                color: .neutral,
                emoji: "🟡"
            )
            qualityRow(
                label: "Mindless",
                time: mindlessTime,
                color: .mindless,
                emoji: "🔴"
            )
        }
    }
    
    private func qualityRow(label: String, time: TimeInterval, color: Color, emoji: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(emoji) \(label)")
                    .font(.subheadline)
                Spacer()
                Text(time.formattedShort)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            ProgressBarView(value: time, total: totalTime, color: color)
        }
    }
}
