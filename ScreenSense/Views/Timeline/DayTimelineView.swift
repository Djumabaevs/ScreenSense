import SwiftUI
import DeviceActivity

struct DayTimelineView: View {
    let report: DailyReport?
    let date: Date
    @State private var showAppDetail: AppUsageEntry?

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var filterForDate: DeviceActivityFilter {
        let start = Calendar.current.startOfDay(for: date)
        let end: Date
        if isToday {
            end = Date()
        } else {
            end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        }
        let interval = DateInterval(start: start, end: end)
        return DeviceActivityFilter(
            segment: .hourly(during: interval),
            users: .all,
            devices: .all
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            if let report, !report.topApps.isEmpty {
                // Summary stats row
                dayStatsRow(report)
                    .springAppear()

                // App entries - tappable
                ForEach(report.topApps.sorted(by: { $0.duration > $1.duration }), id: \.appIdentifier) { entry in
                    TimelineEntryView(entry: entry) {
                        showAppDetail = entry
                    }
                }
            } else {
                // Use live DeviceActivityReport for today
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: isToday ? "waveform" : "chart.bar.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isToday ? .green : .secondary)

                        Text(isToday ? "Live Activity" : "Activity")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Spacer()

                        if isToday {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )

                    DeviceActivityReport(.totalActivity, filter: filterForDate)
                }
            }
        }
        .padding()
        .sheet(item: $showAppDetail) { entry in
            AppDetailSheet(entry: entry)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Day Stats Summary

    @ViewBuilder
    private func dayStatsRow(_ report: DailyReport) -> some View {
        HStack(spacing: 8) {
            miniStat(icon: "clock.fill", value: report.totalScreenTime.formattedShort, color: .blue)
            miniStat(icon: "bolt.fill", value: "\(report.totalScreenTime > 0 ? Int(report.productiveTime / report.totalScreenTime * 100) : 0)%", color: .green)
            miniStat(icon: "hand.tap.fill", value: "\(report.topApps.reduce(0) { $0 + $1.pickupCount })", color: .purple)
            miniStat(icon: "star.fill", value: "\(report.score)", color: .orange)
        }
    }

    private func miniStat(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 0.5)
        )
    }
}
