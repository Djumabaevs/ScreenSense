import SwiftUI

struct DayTimelineView: View {
    let report: DailyReport?
    let date: Date
    
    var body: some View {
        VStack(spacing: 12) {
            if let report, !report.topApps.isEmpty {
                ForEach(report.topApps.sorted(by: { $0.duration > $1.duration }), id: \.appIdentifier) { entry in
                    TimelineEntryView(entry: entry)
                }
            } else {
                EmptyStateView(
                    icon: "clock",
                    title: "No Data Yet",
                    message: "Screen time data will appear here as you use your apps throughout the day."
                )
            }
        }
        .padding()
    }
}
