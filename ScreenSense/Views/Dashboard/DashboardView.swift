import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @State private var showMoodCheck = false
    @State private var showAppDetail: AppUsageEntry?
    
    private var todayReport: DailyReport? {
        reports.first { Calendar.current.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    scoreSection
                    qualityBreakdown
                    topAppsSection
                    insightSection
                    quickStatsSection
                }
                .padding()
            }
            .navigationTitle("ScreenSense")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showMoodCheck = true
                    } label: {
                        Text(latestMoodEmoji)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showMoodCheck) {
                MoodCheckSheet()
                    .presentationDetents([.medium])
            }
            .sheet(item: $showAppDetail) { entry in
                AppDetailSheet(entry: entry)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var latestMoodEmoji: String {
        "😊"
    }
    
    // MARK: - Score Section
    private var scoreSection: some View {
        GlassCard(style: .elevated) {
            VStack(spacing: 12) {
                ScoreRingView(score: todayReport?.score ?? 0, size: 180)
                
                Text("Today's Screen Health")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text((todayReport?.totalScreenTime ?? 0).formattedShort)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    + Text(" total")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .springAppear()
    }
    
    // MARK: - Quality Breakdown
    private var qualityBreakdown: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Quality Breakdown")
                    .font(.headline)
                
                QualityBreakdownView(report: todayReport)
            }
        }
        .springAppear(delay: 0.1)
    }
    
    // MARK: - Top Apps
    private var topAppsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Top Apps Today")
                    .font(.headline)
                
                TopAppsView(
                    apps: todayReport?.topApps ?? [],
                    onAppTap: { entry in showAppDetail = entry }
                )
            }
        }
        .springAppear(delay: 0.2)
    }
    
    // MARK: - Insight
    private var insightSection: some View {
        Group {
            if let insight = todayReport?.insights.first(where: { !$0.isRead }) {
                InsightCardView(insight: insight)
                    .springAppear(delay: 0.3)
            }
        }
    }
    
    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        QuickStatsView(report: todayReport)
            .springAppear(delay: 0.4)
    }
}
