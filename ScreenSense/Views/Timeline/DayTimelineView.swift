import SwiftUI
import DeviceActivity

struct DayTimelineView: View {
    let report: DailyReport?
    let date: Date

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
                ForEach(report.topApps.sorted(by: { $0.duration > $1.duration }), id: \.appIdentifier) { entry in
                    TimelineEntryView(entry: entry)
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
                        .frame(minHeight: 800)
                        .overlay {
                            Color.white.opacity(0.001)
                        }
                }
            }
        }
        .padding()
    }
}
