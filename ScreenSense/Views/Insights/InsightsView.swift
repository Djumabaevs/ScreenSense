import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(sort: \Insight.date, order: .reverse) private var insights: [Insight]
    @Query(sort: \WeeklyDigest.weekStart, order: .reverse) private var digests: [WeeklyDigest]
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @State private var showWeeklyDigest = false
    @State private var showBrainSheet = false
    @State private var showInsightDetail: Insight?

    private var todayReport: DailyReport? {
        reports.first { Calendar.current.isDateInToday($0.date) }
    }

    private var todayInsights: [Insight] {
        insights.filter { Calendar.current.isDateInToday($0.date) && !$0.isRead }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly digest card (if available from SwiftData)
                    if let digest = digests.first {
                        weeklyDigestCard(digest)
                    }

                    // Native insights cards (tappable)
                    nativeInsightsSection

                    // Patterns section
                    patternsSection
                }
                .padding()
                .padding(.bottom, 32)
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showBrainSheet = true
                    } label: {
                        Image(systemName: "brain.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showWeeklyDigest) {
                if let digest = digests.first {
                    WeeklyDigestView(digest: digest)
                }
            }
            .sheet(isPresented: $showBrainSheet) {
                BrainAnalysisSheet()
            }
            .sheet(item: $showInsightDetail) { insight in
                InsightDetailView(insight: insight)
            }
            .sheet(item: $showSmartInsightDetail) { item in
                SmartInsightDetailSheet(insight: item)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Native Insights Section

    @ViewBuilder
    private var nativeInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Insights", systemImage: "sparkles")
                .font(.headline)

            if !todayInsights.isEmpty {
                ForEach(todayInsights, id: \.id) { insight in
                    Button {
                        showInsightDetail = insight
                    } label: {
                        insightRow(insight)
                    }
                    .buttonStyle(.plain)
                }
            } else if let report = todayReport {
                // Generate smart insights from report data
                ForEach(Array(generateSmartInsights(from: DisplayReport.from(report)).enumerated()), id: \.offset) { _, item in
                    smartInsightCard(item)
                }
            } else if let dr = DisplayReport.loadFromSharedContainers() {
                // Fallback: generate insights from shared container data
                ForEach(Array(generateSmartInsights(from: dr).enumerated()), id: \.offset) { _, item in
                    smartInsightCard(item)
                }
            } else {
                GlassCard(style: .subtle) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Insights Coming Soon")
                                .font(.subheadline.bold())
                            Text("Use your device for a few minutes to generate personalized insights.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func insightRow(_ insight: Insight) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: insight.type.icon)
                    .font(.title3)
                    .foregroundStyle(insightColor(for: insight.type))
                    .frame(width: 36, height: 36)
                    .background(insightColor(for: insight.type).opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(insight.title)
                            .font(.subheadline.bold())
                        if insight.severity == .important || insight.severity == .critical {
                            Text(insight.severity.emoji)
                                .font(.caption)
                        }
                    }
                    Text(insight.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func insightColor(for type: InsightType) -> Color {
        switch type {
        case .productiveStreak: return .green
        case .doomScrolling: return .red
        case .lateNightUsage: return .indigo
        case .pickupHabit: return .blue
        case .longSession: return .orange
        case .moodCorrelation: return .yellow
        case .improvementTrend: return .green
        case .weeklyComparison: return .purple
        case .appSwitch: return .purple
        case .suggestion: return .yellow
        }
    }

    // MARK: - Smart Insights Generator

    struct SmartInsight: Hashable, Identifiable {
        let id = UUID()
        let icon: String
        let iconColor: Color
        let title: String
        let body: String
        func hash(into hasher: inout Hasher) { hasher.combine(title) }
        static func == (lhs: SmartInsight, rhs: SmartInsight) -> Bool { lhs.title == rhs.title }
    }

    private func generateSmartInsights(from report: DisplayReport) -> [SmartInsight] {
        var results: [SmartInsight] = []
        let productivePct = report.totalScreenTime > 0 ? Int(report.productiveTime / report.totalScreenTime * 100) : 0
        let mindlessPct = report.totalScreenTime > 0 ? Int(report.mindlessTime / report.totalScreenTime * 100) : 0
        let pickups = report.pickups
        let topApp = report.apps.first

        // Most used app
        if let app = topApp {
            results.append(SmartInsight(
                icon: "star.fill",
                iconColor: .blue,
                title: "Most Used App",
                body: "\(app.name) — \(app.duration.formattedShort) today"
            ))
        }

        // Productive focus
        if productivePct >= 60 {
            results.append(SmartInsight(
                icon: "bolt.fill",
                iconColor: .green,
                title: "Focused Day",
                body: "\(productivePct)% of your screen time was productive. Great job staying on track!"
            ))
        } else if productivePct < 30 {
            results.append(SmartInsight(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "Low Productivity",
                body: "Only \(productivePct)% productive time. Try blocking distracting apps tomorrow."
            ))
        }

        // Pickups
        if pickups > 60 {
            results.append(SmartInsight(
                icon: "hand.tap.fill",
                iconColor: .red,
                title: "High Pickups",
                body: "\(pickups) pickups so far. Batch-check notifications to reduce interruptions."
            ))
        } else if pickups > 30 {
            results.append(SmartInsight(
                icon: "hand.tap.fill",
                iconColor: .blue,
                title: "Moderate Pickups",
                body: "\(pickups) pickups so far. Batch-check notifications to reduce interruptions."
            ))
        } else if pickups > 0 {
            results.append(SmartInsight(
                icon: "hand.thumbsup.fill",
                iconColor: .green,
                title: "Low Pickups",
                body: "Only \(pickups) pickups — excellent self-control!"
            ))
        }

        // App switching
        let appCount = report.apps.count
        if appCount > 15 {
            results.append(SmartInsight(
                icon: "square.grid.2x2.fill",
                iconColor: .purple,
                title: "App Switching",
                body: "You've used \(appCount) different apps. Frequent context-switching reduces deep focus. Try closing unused apps."
            ))
        }

        // High screen time
        let totalHours = report.totalScreenTime / 3600
        if totalHours > 5 {
            results.append(SmartInsight(
                icon: "clock.badge.exclamationmark",
                iconColor: .red,
                title: "High Screen Time",
                body: "\(report.totalScreenTime.formattedShort) total today. Take a 20-second break every 20 minutes to rest your eyes."
            ))
        }

        // Mindless scrolling
        if mindlessPct > 40 {
            let mindlessApps = report.apps.filter { $0.quality == .mindless }
            let appName = mindlessApps.first?.name ?? "apps"
            results.append(SmartInsight(
                icon: "arrow.down.circle.fill",
                iconColor: .red,
                title: "Mindless Scrolling",
                body: "\(mindlessPct)% of time was mindless, mostly on \(appName). Set a timer to limit usage."
            ))
        }

        // Daily tip
        let tips = [
            SmartInsight(icon: "lightbulb.fill", iconColor: .yellow, title: "Daily Tip", body: "Charge your phone outside the bedroom for better sleep quality."),
            SmartInsight(icon: "lightbulb.fill", iconColor: .yellow, title: "Daily Tip", body: "Try the Pomodoro technique: 25 min focused work, 5 min break."),
            SmartInsight(icon: "lightbulb.fill", iconColor: .yellow, title: "Daily Tip", body: "Set a wind-down routine 1 hour before bed without screens.")
        ]
        let dayIndex = Calendar.current.component(.day, from: Date()) % tips.count
        results.append(tips[dayIndex])

        return results
    }

    @State private var showSmartInsightDetail: SmartInsight?

    private func smartInsightCard(_ item: SmartInsight) -> some View {
        TappableGlassCard(action: { showSmartInsightDetail = item }) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundStyle(item.iconColor)
                    .frame(width: 36, height: 36)
                    .background(item.iconColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.bold())
                    Text(item.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Patterns Section

    @State private var showMoodPattern = false
    @State private var showUsagePattern = false
    @State private var showTrendsPattern = false

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns")
                .font(.headline)

            if let correlation = MoodAnalyzer.shared.moodScreenTimeCorrelation(moods: moods, reports: reports) {
                TappableGlassCard(action: { showMoodPattern = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "face.smiling")
                            .font(.title3)
                            .foregroundStyle(.yellow)
                            .frame(width: 36, height: 36)
                            .background(.yellow.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mood + Usage")
                                .font(.subheadline.bold())
                            Text(correlation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // Week-over-week comparison if enough data
            if reports.count >= 7 {
                weekComparisonCard
            }

            TappableGlassCard(action: { showUsagePattern = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                        .background(.blue.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Usage Patterns")
                            .font(.subheadline.bold())
                        Text("Discover your peak hours and usage trends.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            TappableGlassCard(action: { showTrendsPattern = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .frame(width: 36, height: 36)
                        .background(.green.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Trends")
                            .font(.subheadline.bold())
                        Text("See how your screen time changes over the week.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .sheet(isPresented: $showMoodPattern) {
            PatternDetailSheet(
                icon: "face.smiling",
                iconColor: .yellow,
                title: "Mood + Usage Correlation",
                description: MoodAnalyzer.shared.moodScreenTimeCorrelation(moods: moods, reports: reports) ?? "Not enough mood data yet.",
                tips: [
                    "Log your mood regularly to see stronger correlations.",
                    "Notice patterns: does social media improve or worsen your mood?",
                    "Try a screen-free activity when feeling low."
                ]
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showUsagePattern) {
            UsagePatternsDetailSheet(reports: reports)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTrendsPattern) {
            WeeklyTrendsDetailSheet(reports: reports)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var weekComparisonCard: some View {
        let thisWeek = Array(reports.prefix(7))
        let lastWeek = Array(reports.dropFirst(7).prefix(7))

        if !lastWeek.isEmpty {
            let thisWeekAvg = thisWeek.reduce(0.0) { $0 + $1.totalScreenTime } / Double(thisWeek.count)
            let lastWeekAvg = lastWeek.reduce(0.0) { $0 + $1.totalScreenTime } / Double(lastWeek.count)
            let diff = thisWeekAvg - lastWeekAvg
            let isImproved = diff < 0

            GlassCard {
                HStack(spacing: 12) {
                    Image(systemName: isImproved ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(isImproved ? .green : .orange)
                        .frame(width: 36, height: 36)
                        .background((isImproved ? Color.green : Color.orange).opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Change")
                            .font(.subheadline.bold())
                        Text("\(abs(Int(diff / 60)))m/day \(isImproved ? "less" : "more") than last week. \(isImproved ? "Keep it up!" : "Try setting daily limits.")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Weekly Digest Card

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
}

// MARK: - Smart Insight Detail Sheet

struct SmartInsightDetailSheet: View {
    let insight: InsightsView.SmartInsight
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(style: .elevated) {
                        VStack(spacing: 16) {
                            Image(systemName: insight.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(insight.iconColor)
                                .frame(width: 64, height: 64)
                                .background(insight.iconColor.opacity(0.15), in: Circle())

                            Text(insight.title)
                                .font(.title2.bold())

                            Text(insight.body)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("What You Can Do", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)

                            Text(actionableAdvice(for: insight.title))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func actionableAdvice(for title: String) -> String {
        switch title {
        case "Most Used App":
            return "Consider whether this app deserves the most time in your day. If it's productive, great! If not, try setting a daily limit."
        case "Focused Day":
            return "Keep it up! Maintaining high productive screen time improves focus and well-being."
        case "Low Productivity":
            return "Try the 2-minute rule: before opening a leisure app, spend 2 minutes on something productive first."
        case "High Pickups":
            return "Each phone pickup costs 5-15 minutes of attention. Try keeping your phone face-down or in another room during focused work."
        case "Moderate Pickups":
            return "You're doing okay, but batching your notification checks to 3-4 times a day could help you focus longer."
        case "Low Pickups":
            return "Excellent discipline! You're avoiding the constant-checking habit that drains attention."
        case "App Switching":
            return "Frequent context-switching reduces deep focus. Try closing all but 2-3 apps at a time."
        case "High Screen Time":
            return "Follow the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds."
        case "Mindless Scrolling":
            return "Set a screen time limit for social media apps. Even 15 fewer minutes makes a difference."
        default:
            return "Small daily improvements compound over time. Focus on one habit change at a time."
        }
    }
}

// MARK: - Pattern Detail Sheets

struct PatternDetailSheet: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let tips: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(style: .elevated) {
                        VStack(spacing: 16) {
                            Image(systemName: icon)
                                .font(.system(size: 36))
                                .foregroundStyle(iconColor)
                                .frame(width: 64, height: 64)
                                .background(iconColor.opacity(0.15), in: Circle())
                            Text(title)
                                .font(.title3.bold())
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Suggestions", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)
                            ForEach(tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    Text(tip)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct UsagePatternsDetailSheet: View {
    let reports: [DailyReport]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(style: .elevated) {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.blue)
                            Text("Usage Patterns")
                                .font(.title3.bold())

                            if reports.count < 3 {
                                Text("Use the app for a few more days to see detailed patterns.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if reports.count >= 3 {
                        let avgTime = reports.prefix(7).reduce(0.0) { $0 + $1.totalScreenTime } / Double(min(reports.count, 7))
                        let avgPickups = reports.prefix(7).reduce(0) { $0 + $1.topApps.reduce(0) { $0 + $1.pickupCount } } / min(reports.count, 7)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Averages (Last 7 Days)", systemImage: "chart.bar.fill")
                                    .font(.headline)

                                HStack {
                                    Text("Avg Screen Time")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(avgTime.formattedShort)
                                        .font(.subheadline.bold())
                                }

                                HStack {
                                    Text("Avg Pickups")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(avgPickups)")
                                        .font(.subheadline.bold())
                                }

                                HStack {
                                    Text("Avg Score")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    let avgScore = reports.prefix(7).reduce(0) { $0 + $1.score } / min(reports.count, 7)
                                    Text("\(avgScore)/100")
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Tips", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)
                            Text("Track your screen time daily to identify your peak usage hours and build healthier habits over time.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Usage Patterns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct WeeklyTrendsDetailSheet: View {
    let reports: [DailyReport]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(style: .elevated) {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32))
                                .foregroundStyle(.green)
                            Text("Weekly Trends")
                                .font(.title3.bold())
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if reports.count >= 2 {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Daily Breakdown", systemImage: "calendar")
                                    .font(.headline)

                                ForEach(Array(reports.prefix(7).enumerated()), id: \.element.date) { _, report in
                                    HStack {
                                        Text(report.date.dayMonthString)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 60, alignment: .leading)

                                        ProgressBarView(
                                            value: report.totalScreenTime,
                                            total: reports.prefix(7).map(\.totalScreenTime).max() ?? 1,
                                            color: report.score >= 60 ? .green : report.score >= 40 ? .orange : .red
                                        )

                                        Text(report.totalScreenTime.formattedShort)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .frame(width: 44, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    } else {
                        GlassCard(style: .subtle) {
                            VStack(spacing: 8) {
                                Text("Keep tracking for a few more days to see weekly trends.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Weekly Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Brain Analysis Sheet

// MARK: - Display Report (works from SwiftData OR SharedDailyData)

struct DisplayReport {
    let totalScreenTime: TimeInterval
    let productiveTime: TimeInterval
    let neutralTime: TimeInterval
    let mindlessTime: TimeInterval
    let score: Int
    let pickups: Int
    let apps: [DisplayApp]

    struct DisplayApp: Identifiable {
        let id: String
        let name: String
        let category: AppCategory
        let quality: ContentQuality
        let duration: TimeInterval
        let pickupCount: Int
    }

    static func from(_ report: DailyReport) -> DisplayReport {
        DisplayReport(
            totalScreenTime: report.totalScreenTime,
            productiveTime: report.productiveTime,
            neutralTime: report.neutralTime,
            mindlessTime: report.mindlessTime,
            score: report.score,
            pickups: report.topApps.reduce(0) { $0 + $1.pickupCount },
            apps: report.topApps.sorted { $0.duration > $1.duration }.map {
                DisplayApp(
                    id: $0.appIdentifier,
                    name: $0.appName.isEmpty ? $0.appIdentifier.split(separator: ".").last.map(String.init) ?? "Unknown" : $0.appName,
                    category: $0.category,
                    quality: $0.contentQuality,
                    duration: $0.duration,
                    pickupCount: $0.pickupCount
                )
            }
        )
    }

    static func from(_ shared: SharedDailyData) -> DisplayReport {
        let hour = Calendar.current.component(.hour, from: shared.generatedAt)
        var productive: TimeInterval = 0
        var neutral: TimeInterval = 0
        var mindless: TimeInterval = 0
        var displayApps: [DisplayApp] = []

        for usage in shared.appUsages.filter({ $0.duration > 0 }).sorted(by: { $0.duration > $1.duration }) {
            let name = usage.appName.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayName = name.isEmpty ? (usage.appIdentifier.split(separator: ".").last.map(String.init) ?? "Unknown") : name
            let category = AppCategory.from(screenTimeCategory: usage.category, appName: displayName)
            let quality = ClassificationEngine.shared.classify(appName: displayName, category: category, duration: usage.duration, timeOfDay: hour)

            switch quality {
            case .productive: productive += usage.duration
            case .neutral: neutral += usage.duration
            case .mindless: mindless += usage.duration
            }

            displayApps.append(DisplayApp(
                id: usage.appIdentifier,
                name: displayName,
                category: category,
                quality: quality,
                duration: usage.duration,
                pickupCount: usage.pickupCount
            ))
        }

        let total = max(shared.totalScreenTime, displayApps.reduce(0) { $0 + $1.duration })
        let score = ScoreEngine.shared.calculateScore(
            totalScreenTime: total,
            productiveTime: productive,
            neutralTime: neutral,
            mindlessTime: mindless,
            lateNightMinutes: 0,
            pickupCount: shared.pickupCount,
            averagePickups: 70,
            goalsCompleted: 0,
            totalGoals: 0,
            moodImprovement: 0
        )

        return DisplayReport(
            totalScreenTime: total,
            productiveTime: productive,
            neutralTime: neutral,
            mindlessTime: mindless,
            score: score,
            pickups: shared.pickupCount,
            apps: displayApps
        )
    }

    static func loadFromSharedContainers() -> DisplayReport? {
        // Source 1: AppGroup UserDefaults
        if let data: SharedDailyData = AppGroupManager.shared.load(forKey: UserDefaultsKeys.sharedLatestDailyData),
           Calendar.current.isDateInToday(data.date) {
            return from(data)
        }

        // Source 2: Direct JSON file
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
            let fileURL = containerURL.appendingPathComponent("latest_daily.json")
            if let fileData = try? Data(contentsOf: fileURL),
               let shared = try? JSONDecoder().decode(SharedDailyData.self, from: fileData),
               Calendar.current.isDateInToday(shared.date) {
                return from(shared)
            }
        }

        // Source 3: Keychain
        if let kcData = KeychainTransport.load(),
           Calendar.current.isDateInToday(kcData.date) {
            return from(kcData)
        }

        return nil
    }
}

struct BrainAnalysisSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @State private var aiEngine = AIAnalysisEngine()
    @State private var showAppDetail: DisplayReport.DisplayApp?
    @State private var displayReport: DisplayReport?

    private var todayReport: DailyReport? {
        reports.first { Calendar.current.isDateInToday($0.date) }
    }

    private var yesterdayReport: DailyReport? {
        reports.first { Calendar.current.isDateInYesterday($0.date) }
    }

    private var weekAvgScreenTime: TimeInterval {
        let weekReports = reports.prefix(7)
        guard !weekReports.isEmpty else { return 0 }
        return weekReports.reduce(0) { $0 + $1.totalScreenTime } / Double(weekReports.count)
    }

    /// Use SwiftData report if available, otherwise fallback to shared container data
    private var effectiveReport: DisplayReport? {
        if let report = todayReport {
            return DisplayReport.from(report)
        }
        return displayReport
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with score
                    brainHeaderSection
                        .springAppear()

                    if let dr = effectiveReport {
                        // Time balance breakdown
                        timeBalanceSection(dr)
                            .springAppear(delay: 0.06)

                        // Quick stats row
                        quickStatsRow(dr)
                            .springAppear(delay: 0.12)

                        // Data-driven assessment
                        assessmentSection(dr)
                            .springAppear(delay: 0.18)

                        // Comparison with yesterday/week
                        comparisonSection(dr)
                            .springAppear(delay: 0.24)

                        // Top apps - tappable
                        topAppsSection(dr)
                            .springAppear(delay: 0.30)

                        // AI Analysis or personalized tips
                        aiAnalysisSection
                            .springAppear(delay: 0.36)

                        // Wellness tips
                        wellnessTipsSection(dr)
                            .springAppear(delay: 0.42)
                    } else {
                        noDataSection
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
            .navigationTitle("Brain Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $showAppDetail) { app in
                DisplayAppDetailSheet(app: app)
                    .presentationDetents([.medium, .large])
            }
            .task {
                // Try to force sync first
                if todayReport == nil {
                    ScreenTimeDataSyncService.shared.syncLatestDailyData(into: modelContext)
                }

                // Load from shared containers as fallback
                if todayReport == nil {
                    displayReport = DisplayReport.loadFromSharedContainers()
                }

                // Try AI analysis if available, otherwise generate local analysis
                if let report = todayReport {
                    if aiEngine.isAvailable {
                        await aiEngine.analyze(report: report, moods: Array(moods.prefix(7)))
                    } else {
                        // Generate a local data-driven analysis as fallback
                        let dr = DisplayReport.from(report)
                        aiEngine.analysisState = .completed(generateLocalAnalysis(from: dr))
                    }
                } else if let dr = effectiveReport {
                    // Even without a DailyReport, generate analysis from shared data
                    aiEngine.analysisState = .completed(generateLocalAnalysis(from: dr))
                }
            }
        }
    }

    // MARK: - Brain Header with Score

    private var brainHeaderSection: some View {
        GlassCard(style: .elevated) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.25), .blue.opacity(0.15), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "brain.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 6, y: 2)
                }

                if let dr = effectiveReport {
                    ScoreRingView(score: dr.score, size: 120, lineWidth: 10)

                    Text(scoreLabel(for: dr.score))
                        .font(.title3.bold())
                        .foregroundStyle(scoreColor(for: dr.score))

                    Text(scoreDescription(for: dr.score))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Deep Analysis")
                        .font(.title2.bold())
                    Text("Start using your device to see analysis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Time Balance

    private func timeBalanceSection(_ report: DisplayReport) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Time Balance", systemImage: "chart.pie.fill")
                    .font(.headline)

                // Visual bar
                GeometryReader { geo in
                    let total = max(report.totalScreenTime, 1)
                    let prodW = geo.size.width * (report.productiveTime / total)
                    let neutW = geo.size.width * (report.neutralTime / total)
                    let mindW = geo.size.width * (report.mindlessTime / total)

                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.green)
                            .frame(width: max(prodW, 4))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.orange)
                            .frame(width: max(neutW, 4))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.red)
                            .frame(width: max(mindW, 4))
                    }
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                HStack(spacing: 16) {
                    timeLabel(color: .green, icon: "bolt.fill", label: "Productive", time: report.productiveTime, total: report.totalScreenTime)
                    Spacer()
                    timeLabel(color: .orange, icon: "circle.fill", label: "Neutral", time: report.neutralTime, total: report.totalScreenTime)
                    Spacer()
                    timeLabel(color: .red, icon: "flame.fill", label: "Mindless", time: report.mindlessTime, total: report.totalScreenTime)
                }
            }
        }
    }

    private func timeLabel(color: Color, icon: String, label: String, time: TimeInterval, total: TimeInterval) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(time.formattedShort)
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            if total > 0 {
                Text("\(Int(time / total * 100))%")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(color)
            }
        }
    }

    // MARK: - Quick Stats

    private func quickStatsRow(_ report: DisplayReport) -> some View {
        HStack(spacing: 10) {
            statPill(
                icon: "clock.fill",
                value: report.totalScreenTime.formattedShort,
                label: "Screen Time",
                color: .blue
            )
            statPill(
                icon: "hand.tap.fill",
                value: "\(report.pickups)",
                label: "Pickups",
                color: .purple
            )
            statPill(
                icon: "square.grid.2x2.fill",
                value: "\(report.apps.count)",
                label: "Apps",
                color: .cyan
            )
        }
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        GlassCard(style: .subtle) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Data-Driven Assessment

    private func assessmentSection(_ report: DisplayReport) -> some View {
        let productivePct = report.totalScreenTime > 0 ? Int(report.productiveTime / report.totalScreenTime * 100) : 0
        let mindlessPct = report.totalScreenTime > 0 ? Int(report.mindlessTime / report.totalScreenTime * 100) : 0
        let pickups = report.pickups
        let totalHours = report.totalScreenTime / 3600

        return GlassCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Today's Assessment", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    if productivePct >= 60 {
                        assessmentRow(icon: "checkmark.seal.fill", color: .green, text: "Excellent focus! \(productivePct)% of your time was productive.")
                    } else if productivePct >= 40 {
                        assessmentRow(icon: "hand.thumbsup.fill", color: .blue, text: "Good balance — \(productivePct)% productive. Push for 60%+ tomorrow.")
                    } else {
                        assessmentRow(icon: "exclamationmark.triangle.fill", color: .orange, text: "Only \(productivePct)% productive time. Try blocking distracting apps.")
                    }

                    if mindlessPct >= 40 {
                        assessmentRow(icon: "flame.fill", color: .red, text: "\(mindlessPct)% mindless scrolling detected. Set app timers to cut back.")
                    }

                    if pickups > 60 {
                        assessmentRow(icon: "iphone.radiowaves.left.and.right", color: .orange, text: "\(pickups) pickups is high. Try batch-checking notifications.")
                    } else if pickups <= 30 {
                        assessmentRow(icon: "star.fill", color: .yellow, text: "Only \(pickups) pickups — great discipline!")
                    }

                    if totalHours > 6 {
                        assessmentRow(icon: "eye.trianglebadge.exclamationmark", color: .red, text: "Over \(Int(totalHours))h of screen time. Schedule regular breaks.")
                    } else if totalHours < 3 {
                        assessmentRow(icon: "leaf.fill", color: .green, text: "Under \(Int(totalHours))h total — healthy screen time habits!")
                    }
                }
            }
        }
    }

    private func assessmentRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.12), in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Comparison Section

    @ViewBuilder
    private func comparisonSection(_ report: DisplayReport) -> some View {
        if yesterdayReport != nil || reports.count >= 3 {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)

                    if let yesterday = yesterdayReport {
                        let diff = report.totalScreenTime - yesterday.totalScreenTime
                        let diffMin = abs(Int(diff / 60))
                        let isLess = diff < 0

                        HStack(spacing: 10) {
                            Image(systemName: isLess ? "arrow.down.right" : "arrow.up.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isLess ? .green : .orange)
                                .frame(width: 28, height: 28)
                                .background((isLess ? Color.green : Color.orange).opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text("vs Yesterday")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text("\(diffMin)m \(isLess ? "less" : "more") screen time")
                                    .font(.subheadline)
                            }

                            Spacer()

                            let scoreDiff = report.score - yesterday.score
                            Text("\(scoreDiff > 0 ? "+" : "")\(scoreDiff) pts")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(scoreDiff >= 0 ? .green : .red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background((scoreDiff >= 0 ? Color.green : Color.red).opacity(0.12), in: Capsule())
                        }
                    }

                    if reports.count >= 3 {
                        let avgDiff = report.totalScreenTime - weekAvgScreenTime
                        let isBelow = avgDiff < 0

                        HStack(spacing: 10) {
                            Image(systemName: isBelow ? "chart.line.downtrend.xyaxis" : "chart.line.uptrend.xyaxis")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isBelow ? .green : .orange)
                                .frame(width: 28, height: 28)
                                .background((isBelow ? Color.green : Color.orange).opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text("vs Weekly Avg")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text("\(abs(Int(avgDiff / 60)))m \(isBelow ? "below" : "above") average")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Top Apps (Tappable)

    private func topAppsSection(_ report: DisplayReport) -> some View {
        let topApps = Array(report.apps.prefix(6))

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Top Apps", systemImage: "square.stack.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(report.apps.count) used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(topApps.enumerated()), id: \.element.id) { index, app in
                    Button {
                        showAppDetail = app
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(app.quality.color.opacity(0.8), in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Text(app.category.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(app.duration.formattedShort)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                if report.totalScreenTime > 0 {
                                    Text("\(Int(app.duration / report.totalScreenTime * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)

                    if index < topApps.count - 1 {
                        Divider().opacity(0.3)
                    }
                }
            }
        }
    }

    // MARK: - AI Analysis Section

    @ViewBuilder
    private var aiAnalysisSection: some View {
        switch aiEngine.analysisState {
        case .idle, .loading:
            loadingSection

        case .completed(let analysis):
            completedSection(analysis)

        case .unavailable:
            EmptyView()

        case .error:
            GlassCard {
                VStack(spacing: 12) {
                    Image(systemName: "brain.fill")
                        .font(.title3)
                        .foregroundStyle(.purple.opacity(0.5))
                    Text("AI analysis unavailable right now.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Task {
                            if let report = todayReport {
                                await aiEngine.analyze(report: report, moods: Array(moods.prefix(7)))
                            }
                        }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Loading State

    private var loadingSection: some View {
        GlassCard(style: .elevated) {
            VStack(spacing: 16) {
                Image(systemName: "brain.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)

                Text("Analyzing your day...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("Using on-device AI to generate personalized insights")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Completed Analysis

    private func completedSection(_ analysis: BrainAnalysis) -> some View {
        VStack(spacing: 16) {
            GlassCard(style: .elevated) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI Analysis", systemImage: "brain.fill")
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text(analysis.overallAssessment)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Strength", systemImage: "arrow.up.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                        Text(analysis.topStrength)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Watch Out", systemImage: "exclamationmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                        Text(analysis.topConcern)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Action Plan", systemImage: "checklist")
                        .font(.subheadline.bold())
                        .foregroundStyle(.purple)

                    ForEach(Array(analysis.actionItems.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                            Text(item)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if !analysis.moodInsight.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mood Connection", systemImage: "face.smiling")
                            .font(.subheadline.bold())
                            .foregroundStyle(.yellow)
                        Text(analysis.moodInsight)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                Task {
                    if let report = todayReport {
                        await aiEngine.analyze(report: report, moods: Array(moods.prefix(7)))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Re-analyze")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.10), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Wellness Tips (Data-Driven)

    private func wellnessTipsSection(_ report: DisplayReport) -> some View {
        let tips = generateTips(for: report)

        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Recommendations", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)

                ForEach(tips, id: \.text) { tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: tip.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(tip.color)
                            .frame(width: 24, height: 24)
                            .background(tip.color.opacity(0.1), in: Circle())
                        Text(tip.text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private struct Tip: Hashable {
        let icon: String
        let color: Color
        let text: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(text)
        }
        static func == (lhs: Tip, rhs: Tip) -> Bool {
            lhs.text == rhs.text
        }
    }

    private func generateTips(for report: DisplayReport) -> [Tip] {
        var tips: [Tip] = []
        let productivePct = report.totalScreenTime > 0 ? report.productiveTime / report.totalScreenTime * 100 : 0
        let mindlessPct = report.totalScreenTime > 0 ? report.mindlessTime / report.totalScreenTime * 100 : 0
        let pickups = report.pickups

        if mindlessPct > 30 {
            let topMindless = report.apps.filter { $0.quality == .mindless }.first
            if let app = topMindless {
                tips.append(Tip(icon: "timer", color: .orange, text: "Set a \(Int(app.duration / 60 / 2))min daily limit on \(app.name)."))
            }
        }

        if pickups > 50 {
            tips.append(Tip(icon: "bell.slash.fill", color: .red, text: "Try enabling Focus mode to cut your \(pickups) pickups in half."))
        }

        if report.totalScreenTime > 5 * 3600 {
            tips.append(Tip(icon: "eye", color: .teal, text: "With \(report.totalScreenTime.formattedShort) today, take a 20-second eye break every 20 minutes."))
        }

        if productivePct < 40 {
            tips.append(Tip(icon: "bolt.fill", color: .green, text: "Try starting your day with a productive app before opening social media."))
        }

        tips.append(Tip(icon: "moon.fill", color: .indigo, text: "Stop screens 1 hour before bed for better sleep quality."))
        tips.append(Tip(icon: "figure.walk", color: .green, text: "Take a 5-minute walk for every hour of screen time."))

        return Array(tips.prefix(5))
    }

    // MARK: - Local Analysis Generator (Fallback when AI unavailable)

    private func generateLocalAnalysis(from dr: DisplayReport) -> BrainAnalysis {
        let totalMin = Int(dr.totalScreenTime / 60)
        let prodPct = dr.totalScreenTime > 0 ? Int(dr.productiveTime / dr.totalScreenTime * 100) : 0
        let mindlessPct = dr.totalScreenTime > 0 ? Int(dr.mindlessTime / dr.totalScreenTime * 100) : 0
        let pickups = dr.pickups
        let topApp = dr.apps.first

        // Assessment
        let assessment: String
        if dr.score >= 80 {
            assessment = "Excellent day! You've spent \(totalMin) minutes with \(prodPct)% productive usage."
        } else if dr.score >= 60 {
            assessment = "Solid day with \(totalMin) minutes of screen time. \(prodPct)% was productive."
        } else if dr.score >= 40 {
            assessment = "You've used your phone for \(totalMin) minutes today. \(mindlessPct)% was mindless scrolling."
        } else {
            assessment = "High screen time at \(totalMin) minutes with \(mindlessPct)% mindless usage. Consider setting limits."
        }

        // Strength
        let strength: String
        if prodPct >= 60 {
            strength = "\(prodPct)% of your screen time was productive — great focus!"
        } else if pickups < 30 {
            strength = "Only \(pickups) pickups shows excellent self-discipline."
        } else if let app = topApp, app.quality == .productive {
            strength = "Most time spent on \(app.name) (\(app.duration.formattedShort)) — a productive choice."
        } else {
            strength = "You're tracking your screen time — awareness is the first step to improvement."
        }

        // Concern
        let concern: String
        if mindlessPct >= 40 {
            let mindlessApp = dr.apps.first { $0.quality == .mindless }
            concern = "Mindless usage at \(mindlessPct)%\(mindlessApp != nil ? ", mostly on \(mindlessApp!.name)" : ""). Try setting app timers."
        } else if pickups > 60 {
            concern = "\(pickups) pickups is high. Each interruption costs 23 minutes of focus."
        } else if dr.totalScreenTime > 6 * 3600 {
            concern = "Over \(totalMin / 60) hours of screen time. Schedule regular breaks for your eyes."
        } else {
            concern = "Keep building healthy habits by maintaining this balance."
        }

        // Action items
        var actions: [String] = []
        if mindlessPct > 30 {
            if let app = dr.apps.first(where: { $0.quality == .mindless }) {
                actions.append("Set a \(Int(app.duration / 60 / 2))-minute daily limit on \(app.name).")
            }
        }
        if pickups > 50 {
            actions.append("Enable Focus mode during work hours to reduce pickups.")
        }
        if dr.totalScreenTime > 5 * 3600 {
            actions.append("Take a 20-second eye break every 20 minutes (20-20-20 rule).")
        }
        if prodPct < 40 {
            actions.append("Start your morning with a productive app before opening social media.")
        }
        if actions.isEmpty {
            actions.append("Try a 5-minute phone-free walk after every hour of screen time.")
            actions.append("Keep your phone out of the bedroom for better sleep.")
        }

        // Mood insight
        let moodInsight: String
        if let latestMood = moods.first, Calendar.current.isDateInToday(latestMood.date) {
            if latestMood.moodLabel.value >= 0.7 && prodPct >= 50 {
                moodInsight = "Your good mood correlates with productive screen time today."
            } else if latestMood.moodLabel.value < 0.4 && mindlessPct > 30 {
                moodInsight = "Low mood may be connected to mindless scrolling. Try a screen break."
            } else {
                moodInsight = "You reported feeling \(latestMood.moodLabel.displayName.lowercased()) today."
            }
        } else {
            moodInsight = ""
        }

        return BrainAnalysis(
            overallAssessment: assessment,
            topStrength: strength,
            topConcern: concern,
            actionItems: Array(actions.prefix(3)),
            moodInsight: moodInsight,
            scoreInterpretation: "Your wellness score of \(dr.score)/100 reflects your screen time balance."
        )
    }

    // MARK: - No Data

    private var noDataSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("No Data Yet")
                    .font(.title3.bold())

                Text("Use your device for a few minutes, then return to Home to sync your screen time data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Helpers

    private func scoreLabel(for score: Int) -> String {
        if score >= 80 { return "Excellent" }
        if score >= 60 { return "Good" }
        if score >= 40 { return "Fair" }
        return "Needs Work"
    }

    private func scoreColor(for score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .blue }
        if score >= 40 { return .orange }
        return .red
    }

    private func scoreDescription(for score: Int) -> String {
        if score >= 80 { return "Your screen habits are healthy and balanced." }
        if score >= 60 { return "Good habits with room for improvement." }
        if score >= 40 { return "Some mindless usage detected. Small changes can help." }
        return "High mindless usage. Try setting app limits and taking breaks."
    }
}

// MARK: - Display App Detail Sheet

struct DisplayAppDetailSheet: View {
    let app: DisplayReport.DisplayApp
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    GlassCard(style: .elevated) {
                        VStack(spacing: 12) {
                            Image(systemName: app.category.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(app.quality.color)
                                .frame(width: 64, height: 64)
                                .background(app.quality.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))

                            Text(app.name)
                                .font(.title2.bold())

                            HStack(spacing: 16) {
                                Label(app.category.displayName, systemImage: app.category.icon)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Label(app.quality.displayName, systemImage: app.quality == .productive ? "bolt.fill" : app.quality == .mindless ? "flame.fill" : "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(app.quality.color)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .springAppear()

                    // Usage Stats
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Usage Stats", systemImage: "chart.bar.fill")
                                .font(.headline)

                            HStack(spacing: 16) {
                                VStack(spacing: 4) {
                                    Text(app.duration.formattedShort)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    Text("Time Used")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 4) {
                                    Text("\(app.pickupCount)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    Text("Pickups")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }

                            ProgressBarView(
                                value: app.duration,
                                total: 3600,
                                color: app.quality.color,
                                height: 8
                            )
                        }
                    }
                    .springAppear(delay: 0.06)

                    // Content Quality
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Content Quality", systemImage: "sparkles")
                                .font(.headline)

                            HStack(spacing: 10) {
                                Text(app.quality.emoji)
                                    .font(.title)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.quality.displayName)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(app.quality.color)
                                    Text(qualityDescription(for: app.quality))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .springAppear(delay: 0.12)
                }
                .padding()
                .padding(.bottom, 40)
            }
            .navigationTitle(app.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func qualityDescription(for quality: ContentQuality) -> String {
        switch quality {
        case .productive: return "This app contributes to your goals and productivity."
        case .neutral: return "This app is neither particularly helpful nor harmful."
        case .mindless: return "This app tends to encourage passive consumption."
        }
    }
}
