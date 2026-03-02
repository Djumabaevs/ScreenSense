import SwiftUI

struct WeekHeatmapView: View {
    let reports: [DailyReport]
    let weekStart: Date
    
    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let hours = [6, 8, 10, 12, 14, 16, 18, 20, 22]
    
    var body: some View {
        VStack(spacing: 20) {
            if !reports.isEmpty {
                let totalTime = reports.reduce(0.0) { $0 + $1.totalScreenTime }
                Text("Total: \(totalTime.formattedShort)")
                    .font(.headline)
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Breakdown")
                        .font(.headline)
                    
                    ForEach(Array(reports.sorted(by: { $0.date < $1.date }).enumerated()), id: \.offset) { index, report in
                        HStack {
                            Text(report.date.shortDayName)
                                .font(.caption.monospacedDigit())
                                .frame(width: 40, alignment: .leading)
                            
                            Text(report.totalScreenTime.formattedShort)
                                .font(.caption.monospacedDigit())
                                .frame(width: 60, alignment: .leading)
                            
                            Spacer()
                            
                            Text("Score: \(report.score)")
                                .font(.caption.bold())
                                .foregroundStyle(Color.scoreColor(for: report.score))
                        }
                        
                        if index < reports.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            
            if reports.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No Week Data",
                    message: "Use your phone throughout the week to see patterns here."
                )
            }
        }
        .padding()
    }
}
