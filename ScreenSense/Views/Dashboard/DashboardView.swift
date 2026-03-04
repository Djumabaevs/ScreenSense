import SwiftUI
import SwiftData
import DeviceActivity

struct DashboardView: View {
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMoodCheck = false
    @State private var showAppDetail: DisplayReport.DisplayApp?
    @State private var showScoreDetail = false
    @State private var showTimeQualityDetail = false
    @State private var showPickupsDetail = false
    @State private var showAppsCountDetail = false
    @State private var showFocusDetail = false
    @State private var refreshAnchor = Date()
    @State private var reportRefreshID = UUID()
    @State private var screenTimeService = ScreenTimeService.shared
    @State private var lastReportGeneratedAt: Date?
    @State private var lastReportTotalScreenTime: TimeInterval = 0
    @State private var lastReportAppCount: Int = 0
    @State private var sharedFallbackData: SharedDailyData?
    @State private var sharedContainerAvailable = true
    @State private var sharedContainerPath = ""

    private var todayReport: DailyReport? {
        reports.first { Calendar.current.isDateInToday($0.date) }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    private var latestMoodEmoji: String {
        if let latest = moods.first, Calendar.current.isDateInToday(latest.date) {
            return latest.moodLabel.emoji
        }
        return "😊"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    permissionCard
                    screenTimeReportSection
                    nativeDashboardCards
                }
                .padding()
                .padding(.bottom, 32)
            }
            .navigationTitle(greeting)
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
            .sheet(item: $showAppDetail) { app in
                DisplayAppDetailSheet(app: app)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showScoreDetail) {
                ScoreDetailSheet(report: effectiveDashboardReport, allReports: reports)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showTimeQualityDetail) {
                TimeQualityDetailSheet(report: effectiveDashboardReport)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPickupsDetail) {
                PickupsDetailSheet(report: effectiveDashboardReport, allReports: reports)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showAppsCountDetail) {
                AppsCountDetailSheet(report: effectiveDashboardReport)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showFocusDetail) {
                FocusDetailSheet(report: effectiveDashboardReport)
                    .presentationDetents([.medium])
            }
            .task {
                await screenTimeService.requestAuthorizationIfNeeded()
                NotificationService.shared.registerCategories()
                screenTimeService.startMonitoringIfAuthorized()
                await refreshPipeline()
            }
            .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                guard scenePhase == .active else { return }
                Task { @MainActor in
                    refreshAnchor = Date()
                    screenTimeService.syncLatestData(modelContext: modelContext)
                    loadReportDiagnostics()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await screenTimeService.requestAuthorizationIfNeeded()
                    screenTimeService.startMonitoringIfAuthorized()
                    await refreshPipeline()
                }
            }
        }
    }

    // MARK: - Permission Card

    @ViewBuilder
    private var permissionCard: some View {
        if !screenTimeService.isAuthorized {
            GlassCard(style: .elevated) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Screen Time Access Needed", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.yellow)

                    Text("Allow Screen Time access to collect app usage and show your daily metrics.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Allow Access") {
                        Task {
                            await screenTimeService.requestAuthorization()
                            screenTimeService.startMonitoringIfAuthorized()
                            await refreshPipeline()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    if let error = screenTimeService.authorizationError {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        if let monitoringError = screenTimeService.monitoringError, screenTimeService.isAuthorized {
            GlassCard {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Monitoring Issue", systemImage: "exclamationmark.circle")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                    Text(monitoringError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        screenTimeService.startMonitoringIfAuthorized()
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Screen Time Report Section (DeviceActivityReport)

    @ViewBuilder
    private var screenTimeReportSection: some View {
        if screenTimeService.isAuthorized {
            VStack(alignment: .leading, spacing: 12) {
                // Section header with refresh button
                HStack {
                    Text("Today")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Spacer()

                    Button {
                        reportRefreshID = UUID()
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            refreshAnchor = Date()
                            screenTimeService.syncLatestData(modelContext: modelContext)
                            loadReportDiagnostics()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Refresh")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.10), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 4)

                // The DeviceActivityReport (renders TotalActivityView from the extension)
                // This is essential: it triggers the extension to run and sync data.
                // The overlay captures scroll gestures so the parent ScrollView works.
                PassthroughView(content:
                    DeviceActivityReport(.totalActivity, filter: filterForToday)
                        .id(reportRefreshID)
                )
                .frame(minHeight: 700)
            }
            .springAppear()
        }
    }

    // MARK: - Native Tappable Dashboard Cards

    @ViewBuilder
    private var nativeDashboardCards: some View {
        if let dr = effectiveDashboardReport, screenTimeService.isAuthorized {
            // Score Ring Card - tappable
            TappableGlassCard(style: .elevated, action: { showScoreDetail = true }) {
                VStack(spacing: 12) {
                    ScoreRingView(score: dr.score, size: 140, lineWidth: 12)

                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("SCREEN HEALTH")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.8)
                    }

                    Text(dr.totalScreenTime.formattedShort)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
            }
            .springAppear()

            // Quick Stats Row - each tappable
            HStack(spacing: 12) {
                TappableGlassCard(style: .subtle, action: { showPickupsDetail = true }) {
                    VStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("\(dr.pickups)")
                            .font(.system(.title3, design: .rounded).bold())
                        Text("PICKUPS")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                }

                TappableGlassCard(style: .subtle, action: { showAppsCountDetail = true }) {
                    VStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                        Text("\(dr.apps.count)")
                            .font(.system(.title3, design: .rounded).bold())
                        Text("APPS")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                }

                TappableGlassCard(style: .subtle, action: { showFocusDetail = true }) {
                    VStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        let focusPct = dr.totalScreenTime > 0 ? Int(dr.productiveTime / dr.totalScreenTime * 100) : 0
                        Text("\(focusPct)%")
                            .font(.system(.title3, design: .rounded).bold())
                        Text("FOCUS")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .springAppear(delay: 0.05)

            // Time Quality Card - tappable
            TappableGlassCard(action: { showTimeQualityDetail = true }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Quality")
                        .font(.headline)

                    timeQualityRow(
                        icon: "bolt.fill",
                        label: "Productive",
                        color: .green,
                        time: dr.productiveTime,
                        total: dr.totalScreenTime
                    )
                    timeQualityRow(
                        icon: "circle.fill",
                        label: "Neutral",
                        color: .yellow,
                        time: dr.neutralTime,
                        total: dr.totalScreenTime
                    )
                    timeQualityRow(
                        icon: "flame.fill",
                        label: "Mindless",
                        color: .red,
                        time: dr.mindlessTime,
                        total: dr.totalScreenTime
                    )
                }
            }
            .springAppear(delay: 0.1)

            // Top Apps Section
            nativeTopAppsSection(dr)
                .springAppear(delay: 0.15)
        } else if screenTimeService.isAuthorized {
            // Extension view above already shows the data — just show sync status
            // Data is visible through the DeviceActivityReport extension view
            EmptyView()
        }
    }

    private func timeQualityRow(icon: String, label: String, color: Color, time: TimeInterval, total: TimeInterval) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
            Spacer()

            GeometryReader { geo in
                let pct = total > 0 ? time / total : 0
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(geo.size.width * pct, 4))
            }
            .frame(width: 100, height: 8)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))

            Text(time.formattedShort)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(width: 50, alignment: .trailing)
        }
    }

    // MARK: - Native Top Apps (Tappable)

    private var effectiveDashboardReport: DisplayReport? {
        if let report = todayReport, !report.topApps.isEmpty {
            return DisplayReport.from(report)
        }
        if let shared = sharedFallbackData, Calendar.current.isDateInToday(shared.date) {
            return DisplayReport.from(shared)
        }
        return DisplayReport.loadFromSharedContainers()
    }

    @ViewBuilder
    private func nativeTopAppsSection(_ dr: DisplayReport) -> some View {
        if !dr.apps.isEmpty {
            let topApps = Array(dr.apps.prefix(8))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Top Apps", systemImage: "square.stack.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Spacer()

                    Text("\(dr.apps.count) used")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 4)

                GlassCard {
                    VStack(spacing: 0) {
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
                                        HStack(spacing: 4) {
                                            Text(app.category.displayName)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text("\u{00B7}")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                            Text(app.quality.displayName)
                                                .font(.caption2)
                                                .foregroundStyle(app.quality.color)
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(app.duration.formattedShort)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        if dr.totalScreenTime > 0 {
                                            Text("\(Int(app.duration / dr.totalScreenTime * 100))%")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(LiquidGlassButtonStyle())

                            if index < topApps.count - 1 {
                                Divider().opacity(0.3)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var filterForToday: DeviceActivityFilter {
        let now = Date()
        let interval = DateInterval(
            start: Calendar.current.startOfDay(for: now),
            end: now
        )
        return DeviceActivityFilter(
            segment: .hourly(during: interval),
            users: .all,
            devices: .all
        )
    }

    @MainActor
    private func refreshPipeline() async {
        reportRefreshID = UUID()
        refreshAnchor = Date()

        for delay in [3.0, 6.0, 12.0] {
            try? await Task.sleep(for: .seconds(delay))
            refreshAnchor = Date()
            screenTimeService.syncLatestData(modelContext: modelContext)
            loadReportDiagnostics()
        }
    }

    private func loadReportDiagnostics() {
        let appGroup = AppGroupManager.shared
        sharedContainerAvailable = appGroup.isSharedContainerAvailable
        sharedContainerPath = appGroup.sharedContainerPath ?? "Unavailable"
        lastReportGeneratedAt = appGroup.load(forKey: UserDefaultsKeys.reportLastGeneratedAt)
        lastReportTotalScreenTime = appGroup.load(forKey: UserDefaultsKeys.reportLastGeneratedTotalScreenTime) ?? 0
        lastReportAppCount = appGroup.load(forKey: UserDefaultsKeys.reportLastGeneratedAppCount) ?? 0
        sharedFallbackData = appGroup.load(forKey: UserDefaultsKeys.sharedLatestDailyData)

        if sharedFallbackData == nil {
            sharedFallbackData = loadDirectFile()
        }

        if sharedFallbackData == nil {
            if let kcData = KeychainTransport.load() {
                sharedFallbackData = kcData
            }
        }
    }

    private func loadDirectFile() -> SharedDailyData? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupID
        ) else { return nil }

        let fileURL = containerURL.appendingPathComponent("latest_daily.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(SharedDailyData.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Context Extensions

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
    static let insights = Self("insights")
}

// MARK: - Score Detail Sheet

struct ScoreDetailSheet: View {
    let report: DisplayReport?
    let allReports: [DailyReport]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let dr = report {
                        GlassCard(style: .elevated) {
                            VStack(spacing: 16) {
                                ScoreRingView(score: dr.score, size: 160, lineWidth: 14)

                                Text(scoreLabel(for: dr.score))
                                    .font(.title2.bold())
                                    .foregroundStyle(scoreColor(for: dr.score))

                                Text(scoreDescription(for: dr.score))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Score Breakdown", systemImage: "chart.bar.fill")
                                    .font(.headline)

                                scoreFactorRow(label: "Screen Time", icon: "clock.fill", value: dr.totalScreenTime.formattedShort, impact: dr.totalScreenTime < 4 * 3600 ? .positive : dr.totalScreenTime < 6 * 3600 ? .neutral : .negative)
                                scoreFactorRow(label: "Productive %", icon: "bolt.fill", value: "\(Int(dr.totalScreenTime > 0 ? dr.productiveTime / dr.totalScreenTime * 100 : 0))%", impact: dr.productiveTime / max(dr.totalScreenTime, 1) > 0.5 ? .positive : .neutral)
                                scoreFactorRow(label: "Mindless %", icon: "flame.fill", value: "\(Int(dr.totalScreenTime > 0 ? dr.mindlessTime / dr.totalScreenTime * 100 : 0))%", impact: dr.mindlessTime / max(dr.totalScreenTime, 1) < 0.3 ? .positive : .negative)
                                scoreFactorRow(label: "Pickups", icon: "hand.tap.fill", value: "\(dr.pickups)", impact: dr.pickups < 40 ? .positive : dr.pickups < 70 ? .neutral : .negative)
                            }
                        }

                        // Recent scores trend
                        if allReports.count >= 2 {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Recent Trend", systemImage: "chart.line.uptrend.xyaxis")
                                        .font(.headline)

                                    ForEach(Array(allReports.prefix(5).enumerated()), id: \.element.date) { _, report in
                                        HStack {
                                            Text(report.date.dayMonthString)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .frame(width: 60, alignment: .leading)

                                            ProgressBarView(
                                                value: Double(report.score),
                                                total: 100,
                                                color: scoreColor(for: report.score)
                                            )

                                            Text("\(report.score)")
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundStyle(scoreColor(for: report.score))
                                                .frame(width: 30)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Screen Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private enum ScoreImpact { case positive, neutral, negative }

    private func scoreFactorRow(label: String, icon: String, value: String, impact: ScoreImpact) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(impactColor(impact))
                .frame(width: 24, height: 24)
                .background(impactColor(impact).opacity(0.12), in: Circle())
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Image(systemName: impactIcon(impact))
                .font(.system(size: 10))
                .foregroundStyle(impactColor(impact))
        }
    }

    private func impactColor(_ impact: ScoreImpact) -> Color {
        switch impact {
        case .positive: return .green
        case .neutral: return .orange
        case .negative: return .red
        }
    }

    private func impactIcon(_ impact: ScoreImpact) -> String {
        switch impact {
        case .positive: return "arrow.up.circle.fill"
        case .neutral: return "minus.circle.fill"
        case .negative: return "arrow.down.circle.fill"
        }
    }

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
        if score >= 80 { return "Your screen habits are healthy and balanced today." }
        if score >= 60 { return "Good habits with some room for improvement." }
        if score >= 40 { return "Some mindless usage detected. Small changes can help." }
        return "High mindless usage. Try setting app limits and taking breaks."
    }
}

// MARK: - Time Quality Detail Sheet

struct TimeQualityDetailSheet: View {
    let report: DisplayReport?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let dr = report {
                        // Visual breakdown bar
                        GlassCard(style: .elevated) {
                            VStack(spacing: 16) {
                                Text("Time Distribution")
                                    .font(.title3.bold())

                                GeometryReader { geo in
                                    let total = max(dr.totalScreenTime, 1)
                                    HStack(spacing: 2) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(.green)
                                            .frame(width: max(geo.size.width * dr.productiveTime / total, 4))
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(.orange)
                                            .frame(width: max(geo.size.width * dr.neutralTime / total, 4))
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(.red)
                                            .frame(width: max(geo.size.width * dr.mindlessTime / total, 4))
                                    }
                                }
                                .frame(height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .frame(maxWidth: .infinity)
                        }

                        qualityCategoryCard(
                            icon: "bolt.fill",
                            title: "Productive",
                            color: .green,
                            time: dr.productiveTime,
                            total: dr.totalScreenTime,
                            description: "Time spent on work, education, and creativity apps.",
                            apps: dr.apps.filter { $0.quality == .productive }
                        )

                        qualityCategoryCard(
                            icon: "circle.fill",
                            title: "Neutral",
                            color: .orange,
                            time: dr.neutralTime,
                            total: dr.totalScreenTime,
                            description: "Messaging, utilities, and everyday apps.",
                            apps: dr.apps.filter { $0.quality == .neutral }
                        )

                        qualityCategoryCard(
                            icon: "flame.fill",
                            title: "Mindless",
                            color: .red,
                            time: dr.mindlessTime,
                            total: dr.totalScreenTime,
                            description: "Social media scrolling and entertainment without intent.",
                            apps: dr.apps.filter { $0.quality == .mindless }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Time Quality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func qualityCategoryCard(icon: String, title: String, color: Color, time: TimeInterval, total: TimeInterval, description: String, apps: [DisplayReport.DisplayApp]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text(time.formattedShort)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    if total > 0 {
                        Text("(\(Int(time / total * 100))%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !apps.isEmpty {
                    Divider().opacity(0.3)
                    ForEach(apps.prefix(5), id: \.id) { app in
                        HStack {
                            Text(app.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text(app.duration.formattedShort)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Pickups Detail Sheet

struct PickupsDetailSheet: View {
    let report: DisplayReport?
    let allReports: [DailyReport]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(style: .elevated) {
                        VStack(spacing: 12) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.blue)
                            Text("\(report?.pickups ?? 0)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            Text("Pickups Today")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            let avg = averagePickups
                            if avg > 0 {
                                let diff = (report?.pickups ?? 0) - avg
                                Text("\(abs(diff)) \(diff <= 0 ? "fewer" : "more") than your average (\(avg))")
                                    .font(.caption)
                                    .foregroundStyle(diff <= 0 ? .green : .orange)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Tips to Reduce Pickups", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)

                            tipRow(text: "Enable Focus mode during work hours")
                            tipRow(text: "Batch-check notifications 3x per day")
                            tipRow(text: "Move distracting apps off your home screen")
                            tipRow(text: "Use a physical watch instead of checking your phone for time")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Pickups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var averagePickups: Int {
        let recent = allReports.prefix(7)
        guard !recent.isEmpty else { return 0 }
        let total = recent.reduce(0) { $0 + $1.topApps.reduce(0) { $0 + $1.pickupCount } }
        return total / recent.count
    }

    private func tipRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Apps Count Detail Sheet

struct AppsCountDetailSheet: View {
    let report: DisplayReport?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(style: .elevated) {
                        VStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.purple)
                            Text("\(report?.apps.count ?? 0)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            Text("Apps Used Today")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if let dr = report {
                        let categories = Dictionary(grouping: dr.apps, by: \.category)
                        let sorted = categories.sorted { $0.value.count > $1.value.count }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("By Category", systemImage: "folder.fill")
                                    .font(.headline)

                                ForEach(sorted, id: \.key) { category, apps in
                                    HStack {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 20)
                                        Text(category.displayName)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(apps.count) apps")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(apps.reduce(0) { $0 + $1.duration }.formattedShort)
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Apps Used")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Focus Detail Sheet

struct FocusDetailSheet: View {
    let report: DisplayReport?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let dr = report {
                        let focusPct = dr.totalScreenTime > 0 ? Int(dr.productiveTime / dr.totalScreenTime * 100) : 0

                        GlassCard(style: .elevated) {
                            VStack(spacing: 12) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.green)
                                Text("\(focusPct)%")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                Text("Focus Score")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Text(focusDescription(focusPct))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Productive Apps", systemImage: "bolt.fill")
                                    .font(.headline)
                                    .foregroundStyle(.green)

                                let productiveApps = dr.apps.filter { $0.quality == .productive }
                                if productiveApps.isEmpty {
                                    Text("No productive app usage recorded yet today.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(productiveApps, id: \.id) { app in
                                        HStack {
                                            Text(app.name)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            Spacer()
                                            Text(app.duration.formattedShort)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func focusDescription(_ pct: Int) -> String {
        if pct >= 70 { return "Exceptional focus today! You're mostly using productive apps." }
        if pct >= 50 { return "Good balance of productive and leisure screen time." }
        if pct >= 30 { return "Moderate focus. Try starting your day with productive apps." }
        return "Low focus today. Consider blocking distracting apps during work hours."
    }
}
