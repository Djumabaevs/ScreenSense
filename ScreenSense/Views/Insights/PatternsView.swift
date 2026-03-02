import SwiftUI

struct PatternsView: View {
    let reports: [DailyReport]
    let moods: [MoodEntry]
    
    var body: some View {
        VStack(spacing: 16) {
            if let correlation = MoodAnalyzer.shared.moodScreenTimeCorrelation(moods: moods, reports: reports) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mood + Usage", systemImage: "face.smiling")
                            .font(.headline)
                        Text(correlation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your Peak Hours", systemImage: "clock")
                        .font(.headline)
                    Text("Analyze your usage patterns over time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
