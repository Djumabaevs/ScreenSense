import DeviceActivity
import SwiftUI

// MARK: - Dashboard Report View (rendered inside the DeviceActivityReport extension)

struct TotalActivityView: View {
    let summary: SharedDailyData
    @State private var showAllApps = false
    @State private var selectedApp: SharedAppUsage?

    // MARK: - Classification

    private func classify(_ app: SharedAppUsage) -> ContentCategory {
        let cat = app.category.lowercased()
        let name = app.appName.lowercased()

        if cat.contains("productivity") || cat.contains("education")
            || cat.contains("developer") || cat.contains("business")
            || cat.contains("reference") || cat.contains("finance")
            || name.contains("xcode") || name.contains("slack")
            || name.contains("notion") || name.contains("figma")
            || name.contains("github") || name.contains("linear")
            || name.contains("vscode") || name.contains("terminal")
            || name.contains("calendar") || name.contains("mail")
            || name.contains("notes") || name.contains("claude") {
            return .productive
        }

        if cat.contains("social") || cat.contains("entertainment")
            || cat.contains("games") || name.contains("tiktok")
            || name.contains("instagram") || name.contains("youtube")
            || name.contains("twitter") || name.contains("reddit")
            || name.contains("snapchat") || name.contains("facebook") {
            return .mindless
        }

        return .neutral
    }

    private enum ContentCategory: Equatable {
        case productive, neutral, mindless

        var label: String {
            switch self {
            case .productive: return "Productive"
            case .neutral: return "Neutral"
            case .mindless: return "Mindless"
            }
        }

        var color: Color {
            switch self {
            case .productive: return Color(red: 0.20, green: 0.84, blue: 0.46)
            case .neutral: return Color(red: 1.0, green: 0.76, blue: 0.03)
            case .mindless: return Color(red: 1.0, green: 0.27, blue: 0.35)
            }
        }

        var icon: String {
            switch self {
            case .productive: return "bolt.fill"
            case .neutral: return "circle.fill"
            case .mindless: return "flame.fill"
            }
        }
    }

    private var qualityBreakdown: (productive: TimeInterval, neutral: TimeInterval, mindless: TimeInterval) {
        var productive: TimeInterval = 0
        var neutral: TimeInterval = 0
        var mindless: TimeInterval = 0

        for app in summary.appUsages {
            switch classify(app) {
            case .productive: productive += app.duration
            case .neutral: neutral += app.duration
            case .mindless: mindless += app.duration
            }
        }

        return (productive, neutral, mindless)
    }

    private var score: Int {
        let q = qualityBreakdown
        let appTotal = q.productive + q.neutral + q.mindless
        guard appTotal > 0 else { return 0 }

        let productiveRatio = q.productive / appTotal
        let mindlessRatio = q.mindless / appTotal

        var s = 50.0 + (productiveRatio * 40.0) - (mindlessRatio * 35.0)

        if appTotal > 8 * 3600 {
            let excessHours = (appTotal - 8 * 3600) / 3600
            s -= excessHours * 3
        }

        if summary.pickupCount < 30 {
            s += 5
        }

        return max(0, min(100, Int(s)))
    }

    private var scoreColor: Color {
        if score >= 70 { return Color(red: 0.20, green: 0.84, blue: 0.46) }
        if score >= 40 { return Color(red: 1.0, green: 0.76, blue: 0.03) }
        return Color(red: 1.0, green: 0.27, blue: 0.35)
    }

    private var scoreGradientColors: [Color] {
        if score >= 70 {
            return [Color(red: 0.10, green: 0.75, blue: 0.40), Color(red: 0.20, green: 0.92, blue: 0.55)]
        }
        if score >= 40 {
            return [Color(red: 1.0, green: 0.65, blue: 0.0), Color(red: 1.0, green: 0.84, blue: 0.04)]
        }
        return [Color(red: 1.0, green: 0.20, blue: 0.28), Color(red: 1.0, green: 0.45, blue: 0.52)]
    }

    private var scoreEmoji: String {
        if score >= 80 { return "🔥" }
        if score >= 60 { return "✨" }
        if score >= 40 { return "👀" }
        return "😬"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Section header
                HStack {
                    Text("Today")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer()
                }
                .padding(.horizontal, 4)

                // Hero score section
                scoreHeroSection

                // Quick stats pills
                statsRow

                // Quality breakdown
                qualitySection

                // Top apps
                if !summary.appUsages.isEmpty {
                    topAppsSection
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 100) // Space for tab bar
        }
        .task {
            // Persist data from extension view context (backup to makeConfiguration saves)
            persistSummaryFromView()
        }
    }

    /// Write summary data from the view rendering context.
    /// This runs in the extension process after the view appears.
    private func persistSummaryFromView() {
        guard let encoded = try? JSONEncoder().encode(summary) else { return }

        // Method 1: UserDefaults via App Group
        if let defaults = UserDefaults(suiteName: AppConstants.appGroupID) {
            defaults.set(encoded, forKey: UserDefaultsKeys.sharedLatestDailyData)
            defaults.set(Date(), forKey: UserDefaultsKeys.sharedLatestDailyDataUpdatedAt)
            defaults.synchronize()
        }

        // Method 2: Direct file write with NSFileCoordinator (handles cross-process access)
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
            let fileURL = containerURL.appendingPathComponent("latest_daily.json")
            var coordError: NSError?
            let coordinator = NSFileCoordinator()
            coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordError) { url in
                try? encoded.write(to: url, options: .atomic)
            }
        }

        // Method 3: Keychain
        KeychainTransport.save(summary)
    }

    // MARK: - Score Hero

    private var scoreHeroSection: some View {
        VStack(spacing: 14) {
            // Score ring
            ZStack {
                // Ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [scoreColor.opacity(0.18), scoreColor.opacity(0.04), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 75
                        )
                    )
                    .frame(width: 150, height: 150)

                // Background track
                Circle()
                    .stroke(
                        Color.gray.opacity(0.10),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        LinearGradient(
                            colors: scoreGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: scoreColor.opacity(0.35), radius: 6, y: 2)

                // Score number
                VStack(spacing: 1) {
                    Text("\(score)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: scoreGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("of 100")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            // Time + label
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(scoreEmoji)
                        .font(.system(size: 13))
                    Text("Screen Health")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.0)
                }

                Text(formattedDuration(summary.totalScreenTime))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(glassBackground(cornerRadius: 22))
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 8) {
            statPill(
                icon: "hand.tap.fill",
                value: "\(summary.pickupCount)",
                label: "Pickups",
                color: Color(red: 0.45, green: 0.60, blue: 1.0)
            )

            statPill(
                icon: "square.grid.2x2.fill",
                value: "\(summary.appUsages.count)",
                label: "Apps",
                color: Color(red: 0.70, green: 0.50, blue: 1.0)
            )

            let q = qualityBreakdown
            let appTotal = q.productive + q.neutral + q.mindless
            let prodPercent = appTotal > 0 ? Int((q.productive / appTotal) * 100) : 0
            statPill(
                icon: "bolt.fill",
                value: "\(prodPercent)%",
                label: "Focus",
                color: ContentCategory.productive.color
            )
        }
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(glassBackground(cornerRadius: 16))
    }

    // MARK: - Quality Section

    private var qualitySection: some View {
        let q = qualityBreakdown
        let appTotal = max(q.productive + q.neutral + q.mindless, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Time Quality")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.leading, 2)

            VStack(spacing: 10) {
                qualityBar(
                    category: .productive,
                    time: q.productive,
                    fraction: q.productive / appTotal
                )
                qualityBar(
                    category: .neutral,
                    time: q.neutral,
                    fraction: q.neutral / appTotal
                )
                qualityBar(
                    category: .mindless,
                    time: q.mindless,
                    fraction: q.mindless / appTotal
                )
            }
        }
        .padding(14)
        .background(glassBackground(cornerRadius: 18))
    }

    private func qualityBar(category: ContentCategory, time: TimeInterval, fraction: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(category.color)
                .frame(width: 16)

            Text(category.label)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 68, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.08))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [category.color.opacity(0.6), category.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(max(CGFloat(fraction), 0), 1))
                        .shadow(color: category.color.opacity(0.3), radius: 2, y: 1)
                }
            }
            .frame(height: 6)

            Text(formattedDuration(time))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .trailing)
        }
    }

    // MARK: - Top Apps

    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Top Apps")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Spacer()

                if summary.appUsages.count > 5 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showAllApps.toggle()
                        }
                    } label: {
                        Text(showAllApps ? "Show Less" : "See All (\(summary.appUsages.count))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                } else {
                    Text("\(summary.appUsages.count) used")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                let appsToShow = showAllApps ? summary.appUsages : Array(summary.appUsages.prefix(5))
                ForEach(Array(appsToShow.enumerated()), id: \.offset) { index, app in
                    Button {
                        selectedApp = app
                    } label: {
                        appRow(app: app, rank: index + 1)
                    }
                    .buttonStyle(.plain)

                    if index < appsToShow.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                            .opacity(0.25)
                    }
                }
            }
        }
        .padding(14)
        .background(glassBackground(cornerRadius: 18))
        .sheet(item: $selectedApp) { app in
            appDetailSheet(app: app)
        }
    }

    // MARK: - App Detail Sheet

    private func appDetailSheet(app: SharedAppUsage) -> some View {
        let category = classify(app)
        let appTotal = summary.appUsages.reduce(0) { $0 + $1.duration }
        let fraction = appTotal > 0 ? app.duration / appTotal : 0

        return VStack(spacing: 20) {
            // Header
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [category.color.opacity(0.7), category.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(String(app.appName.prefix(1)).uppercased())
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                Text(app.appName.isEmpty ? app.appIdentifier : app.appName)
                    .font(.title3.bold())

                Text(app.category.isEmpty ? "Other" : app.category)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(formattedDuration(app.duration))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Time Used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(Int(fraction * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(category.color)
                    Text("of Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text(category.label)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(category.color)
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(glassBackground(cornerRadius: 16))

            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func appRow(app: SharedAppUsage, rank: Int) -> some View {
        let category = classify(app)
        let appTotal = summary.appUsages.reduce(0) { $0 + $1.duration }
        let fraction = appTotal > 0 ? app.duration / appTotal : 0

        return HStack(spacing: 10) {
            // Rank badge
            Text("\(rank)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [category.color.opacity(0.85), category.color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: category.color.opacity(0.25), radius: 3, y: 1)
                )

            // App info
            VStack(alignment: .leading, spacing: 1) {
                Text(app.appName.isEmpty ? app.appIdentifier : app.appName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(app.category.isEmpty ? "Other" : app.category)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Duration + percentage
            VStack(alignment: .trailing, spacing: 1) {
                Text(formattedDuration(app.duration))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))

                Text("\(Int(fraction * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 7)
    }

    // MARK: - Glass Background Helper

    private func glassBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.20), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    // MARK: - Helpers

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: interval) ?? "0m"
    }
}

// MARK: - Insights Report View (rendered inside the extension for Insights tab)

struct InsightsReportView: View {
    let summary: SharedDailyData

    private func classify(_ app: SharedAppUsage) -> String {
        let cat = app.category.lowercased()
        let name = app.appName.lowercased()

        if cat.contains("productivity") || cat.contains("education")
            || cat.contains("developer") || cat.contains("business")
            || cat.contains("reference") || cat.contains("finance")
            || name.contains("xcode") || name.contains("slack")
            || name.contains("notion") || name.contains("figma")
            || name.contains("github") || name.contains("linear")
            || name.contains("vscode") || name.contains("terminal")
            || name.contains("calendar") || name.contains("mail")
            || name.contains("notes") || name.contains("claude") {
            return "productive"
        }

        if cat.contains("social") || cat.contains("entertainment")
            || cat.contains("games") || name.contains("tiktok")
            || name.contains("instagram") || name.contains("youtube")
            || name.contains("twitter") || name.contains("reddit")
            || name.contains("snapchat") || name.contains("facebook") {
            return "mindless"
        }

        return "neutral"
    }

    private var qualityBreakdown: (productive: TimeInterval, neutral: TimeInterval, mindless: TimeInterval) {
        var productive: TimeInterval = 0
        var neutral: TimeInterval = 0
        var mindless: TimeInterval = 0

        for app in summary.appUsages {
            switch classify(app) {
            case "productive": productive += app.duration
            case "mindless": mindless += app.duration
            default: neutral += app.duration
            }
        }

        return (productive, neutral, mindless)
    }

    private struct InsightItem: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let title: String
        let body: String
        let priority: Int
    }

    private var insights: [InsightItem] {
        var items: [InsightItem] = []
        let q = qualityBreakdown
        let appTotal = q.productive + q.neutral + q.mindless

        // Top app insight
        if let topApp = summary.appUsages.first {
            items.append(InsightItem(
                icon: "star.fill",
                color: .blue,
                title: "Most Used App",
                body: "\(topApp.appName.isEmpty ? topApp.appIdentifier : topApp.appName) — \(formattedDuration(topApp.duration)) today",
                priority: 1
            ))
        }

        // Productivity insight
        if appTotal > 0 {
            let prodPct = Int((q.productive / appTotal) * 100)
            let mindPct = Int((q.mindless / appTotal) * 100)

            if prodPct >= 60 {
                items.append(InsightItem(
                    icon: "bolt.fill",
                    color: Color(red: 0.2, green: 0.84, blue: 0.46),
                    title: "Focused Day 🎯",
                    body: "\(prodPct)% of your screen time was productive. Great job staying on track!",
                    priority: 2
                ))
            } else if mindPct >= 50 {
                items.append(InsightItem(
                    icon: "exclamationmark.triangle.fill",
                    color: Color(red: 1.0, green: 0.55, blue: 0.0),
                    title: "Scroll Alert ⚠️",
                    body: "\(mindPct)% of your time went to social media & entertainment. Try the 5-minute rule before opening these apps.",
                    priority: 2
                ))
            } else {
                items.append(InsightItem(
                    icon: "circle.fill",
                    color: Color(red: 1.0, green: 0.76, blue: 0.03),
                    title: "Balanced Usage",
                    body: "Your time is split fairly evenly. Consider setting focused work blocks to boost productivity.",
                    priority: 2
                ))
            }
        }

        // Pickup insight
        if summary.pickupCount > 60 {
            items.append(InsightItem(
                icon: "hand.tap.fill",
                color: Color(red: 1.0, green: 0.27, blue: 0.35),
                title: "High Pickups",
                body: "\(summary.pickupCount) pickups is above average. Each pickup breaks your flow. Try placing your phone face-down.",
                priority: 3
            ))
        } else if summary.pickupCount > 30 {
            items.append(InsightItem(
                icon: "hand.tap.fill",
                color: Color(red: 1.0, green: 0.76, blue: 0.03),
                title: "Moderate Pickups",
                body: "\(summary.pickupCount) pickups so far. Batch-check notifications to reduce interruptions.",
                priority: 3
            ))
        } else if summary.pickupCount > 0 {
            items.append(InsightItem(
                icon: "hand.tap.fill",
                color: Color(red: 0.2, green: 0.84, blue: 0.46),
                title: "Low Pickups ✅",
                body: "Only \(summary.pickupCount) pickups — excellent self-control! You're avoiding the distraction loop.",
                priority: 3
            ))
        }

        // App diversity insight
        if summary.appUsages.count > 15 {
            items.append(InsightItem(
                icon: "square.grid.3x3.fill",
                color: Color(red: 0.70, green: 0.50, blue: 1.0),
                title: "App Switching",
                body: "You've used \(summary.appUsages.count) different apps. Frequent context-switching reduces deep focus. Try closing unused apps.",
                priority: 4
            ))
        }

        // Social media specific
        let socialApps = summary.appUsages.filter { classify($0) == "mindless" }
        let socialTime = socialApps.reduce(0) { $0 + $1.duration }
        if socialTime > 3600 {
            let topSocial = socialApps.max(by: { $0.duration < $1.duration })
            items.append(InsightItem(
                icon: "bubble.left.and.bubble.right.fill",
                color: Color(red: 1.0, green: 0.27, blue: 0.35),
                title: "Social Media Time",
                body: "\(formattedDuration(socialTime)) on social & entertainment\(topSocial.map { " — mostly \($0.appName.isEmpty ? $0.appIdentifier : $0.appName)" } ?? ""). Set a daily limit to take back your time.",
                priority: 5
            ))
        }

        // Screen time insight
        let totalHours = summary.totalScreenTime / 3600
        if totalHours > 6 {
            items.append(InsightItem(
                icon: "clock.fill",
                color: Color(red: 1.0, green: 0.55, blue: 0.0),
                title: "High Screen Time",
                body: "\(formattedDuration(summary.totalScreenTime)) total today. Take a 20-second break every 20 minutes to rest your eyes.",
                priority: 6
            ))
        }

        return items.sorted { $0.priority < $1.priority }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if insights.isEmpty {
                    emptyState
                } else {
                    ForEach(insights) { insight in
                        insightCard(insight)
                    }
                }

                // Quick tip
                quickTipCard
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 40)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Insights Generating...")
                .font(.system(size: 15, weight: .semibold, design: .rounded))

            Text("Use your phone for a while and come back to see personalized insights.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(glassBackground(cornerRadius: 20))
    }

    private func insightCard(_ insight: InsightItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(insight.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(insight.color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Text(insight.body)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(glassBackground(cornerRadius: 16))
    }

    private var quickTipCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundStyle(.yellow)

            Text(randomTip)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.yellow.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.yellow.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    private var randomTip: String {
        let tips = [
            "Try the 20-20-20 rule: every 20 min, look at something 20 feet away for 20 seconds.",
            "Set your phone to grayscale to make social apps less appealing.",
            "Leave your phone in another room during meals for better mindfulness.",
            "Use Do Not Disturb during your most productive hours.",
            "Charge your phone outside the bedroom for better sleep quality.",
        ]
        let index = Calendar.current.component(.hour, from: Date()) % tips.count
        return tips[index]
    }

    private func glassBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.20), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: interval) ?? "0m"
    }
}
