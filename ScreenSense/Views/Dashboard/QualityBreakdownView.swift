import SwiftUI

struct QualityBreakdownView: View {
    let report: DailyReport?
    
    private var totalTime: TimeInterval {
        report?.totalScreenTime ?? 1
    }
    
    var body: some View {
        VStack(spacing: 12) {
            qualityRow(
                label: "Productive",
                time: report?.productiveTime ?? 0,
                color: .productive,
                emoji: "🟢"
            )
            qualityRow(
                label: "Neutral",
                time: report?.neutralTime ?? 0,
                color: .neutral,
                emoji: "🟡"
            )
            qualityRow(
                label: "Mindless",
                time: report?.mindlessTime ?? 0,
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
