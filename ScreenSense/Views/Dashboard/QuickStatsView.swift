import SwiftUI

struct QuickStatsView: View {
    let report: DailyReport?
    var allReports: [DailyReport] = []

    private var pickupCount: Int {
        report?.topApps.reduce(0) { $0 + $1.pickupCount } ?? 0
    }

    private var avgSession: TimeInterval {
        let apps = report?.topApps ?? []
        guard !apps.isEmpty else { return 0 }
        let total = apps.reduce(0.0) { $0 + $1.duration }
        let sessions = apps.reduce(0) { $0 + max($1.pickupCount, 1) }
        return total / Double(sessions)
    }

    private var streak: Int {
        let calendar = Calendar.current
        let sorted = allReports.sorted { $0.date > $1.date }
        guard !sorted.isEmpty else { return 0 }

        var count = 0
        var expectedDate = calendar.startOfDay(for: Date())

        for report in sorted {
            let reportDay = calendar.startOfDay(for: report.date)
            if reportDay == expectedDate {
                count += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if reportDay < expectedDate {
                break
            }
        }
        return count
    }

    var body: some View {
        HStack(spacing: 12) {
            statCard(icon: "iphone", value: "\(pickupCount)", label: "Pickups")
            statCard(icon: "clock", value: avgSession.formattedShort, label: "Avg Sess")
            statCard(icon: "flame.fill", value: "\(streak)", label: "Streak")
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        GlassCard(style: .subtle) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title3, design: .rounded).bold())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
