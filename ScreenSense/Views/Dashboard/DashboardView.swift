import SwiftUI
import SwiftData
import DeviceActivity

struct DashboardView: View {
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMoodCheck = false
    @State private var showAppDetail: AppUsageEntry?
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    permissionCard
                    screenTimeReportSection
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
            .sheet(item: $showAppDetail) { entry in
                AppDetailSheet(entry: entry)
                    .presentationDetents([.medium, .large])
            }
            .task {
                await screenTimeService.requestAuthorizationIfNeeded()
                NotificationService.shared.registerCategories()
                screenTimeService.startMonitoringIfAuthorized()
                await refreshPipeline()
            }
            .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { _ in
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

    private var latestMoodEmoji: String {
        "😊"
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

    // MARK: - Screen Time Report Section

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
                // Overlay captures scroll gestures so the parent ScrollView works smoothly
                DeviceActivityReport(.totalActivity, filter: filterForToday)
                    .id(reportRefreshID)
                    .frame(minHeight: 800)
                    .overlay {
                        Color.white.opacity(0.001)
                    }
            }
            .springAppear()
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
