import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Insight.date, order: .reverse) private var insights: [Insight]
    @Query(sort: \WeeklyDigest.weekStart, order: .reverse) private var digests: [WeeklyDigest]
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @State private var showWeeklyDigest = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let digest = digests.first {
                        weeklyDigestCard(digest)
                    }
                    
                    insightsSection
                    patternsSection
                }
                .padding()
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "brain")
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showWeeklyDigest) {
                if let digest = digests.first {
                    WeeklyDigestView(digest: digest)
                }
            }
        }
    }
    
    private func weeklyDigestCard(_ digest: WeeklyDigest) -> some View {
        Button {
            showWeeklyDigest = true
        } label: {
            GlassCard(style: .elevated) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Weekly Digest", systemImage: "doc.text.fill")
                            .font(.headline)
                        Text(digest.topInsight)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Tap to see full report")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .springAppear()
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Insights")
                .font(.headline)
            
            let todayInsights = insights.filter { Calendar.current.isDateInToday($0.date) }
            
            if todayInsights.isEmpty {
                GlassCard(style: .subtle) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.secondary)
                        Text("AI insights will appear as you use your phone today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(Array(todayInsights.enumerated()), id: \.element.id) { index, insight in
                    InsightCardView(insight: insight)
                        .springAppear(delay: Double(index) * 0.05)
                }
            }
        }
    }
    
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns")
                .font(.headline)
            
            if let correlation = MoodAnalyzer.shared.moodScreenTimeCorrelation(moods: moods, reports: reports) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mood + Usage", systemImage: "face.smiling")
                            .font(.subheadline.bold())
                        Text(correlation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your Peak Hours", systemImage: "clock")
                        .font(.subheadline.bold())
                    Text("Use the app for a few days to see your peak usage hours")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
