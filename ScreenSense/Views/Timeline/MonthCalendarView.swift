import SwiftUI

struct MonthCalendarView: View {
    let reports: [DailyReport]
    let month: Date
    
    var body: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Stats")
                        .font(.headline)
                    
                    if !reports.isEmpty {
                        let avgDaily = reports.reduce(0.0) { $0 + $1.totalScreenTime } / Double(reports.count)
                        let avgScore = reports.reduce(0) { $0 + $1.score } / max(reports.count, 1)
                        let bestDay = reports.max(by: { $0.score < $1.score })
                        let worstDay = reports.min(by: { $0.score < $1.score })
                        
                        statsRow(label: "Avg Daily", value: avgDaily.formattedShort)
                        statsRow(label: "Avg Score", value: "\(avgScore)")
                        
                        if let best = bestDay {
                            statsRow(label: "Best Day", value: "\(best.date.dayMonthString) (\(best.score))")
                        }
                        if let worst = worstDay {
                            statsRow(label: "Worst Day", value: "\(worst.date.dayMonthString) (\(worst.score))")
                        }
                        
                        let totalProductive = reports.reduce(0.0) { $0 + $1.productiveTime }
                        let totalTime = reports.reduce(0.0) { $0 + $1.totalScreenTime }
                        if totalTime > 0 {
                            statsRow(label: "Productive", value: "\(Int(totalProductive / totalTime * 100))%")
                            
                            let totalMindless = reports.reduce(0.0) { $0 + $1.mindlessTime }
                            statsRow(label: "Mindless", value: "\(Int(totalMindless / totalTime * 100))%")
                        }
                    } else {
                        Text("No data for this month yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
    
    private func statsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
