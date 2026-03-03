import SwiftUI
import SwiftData
import Foundation

struct CreateGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @State private var selectedType: GoalType?
    @State private var targetValue: Double = 180
    @State private var selectedApp: String = ""
    @State private var showAppPicker = false
    @State private var appSearchText = ""
    @State private var customAppName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if selectedType == nil {
                        goalTypePicker
                    } else {
                        goalConfigurator
                    }
                }
                .padding()
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedType != nil {
                        Button {
                            withAnimation { selectedType = nil }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Back")
                            }
                        }
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .sheet(isPresented: $showAppPicker) {
            appPickerSheet
        }
    }

    // MARK: - App Picker Sheet

    private var appPickerSheet: some View {
        NavigationStack {
            List {
                if !allAvailableApps.isEmpty {
                    Section("Your Apps") {
                        ForEach(filteredAvailableApps, id: \.self) { appName in
                            Button {
                                selectedApp = appName
                                showAppPicker = false
                            } label: {
                                HStack {
                                    Text(appName)
                                    Spacer()
                                    if selectedApp == appName {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Common Apps") {
                    ForEach(filteredCommonApps, id: \.self) { appName in
                        Button {
                            selectedApp = appName
                            showAppPicker = false
                        } label: {
                            HStack {
                                Text(appName)
                                Spacer()
                                if selectedApp == appName {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Custom") {
                    HStack {
                        TextField("Type app name...", text: $customAppName)
                        if !customAppName.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button("Add") {
                                selectedApp = customAppName.trimmingCharacters(in: .whitespaces)
                                customAppName = ""
                                showAppPicker = false
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .searchable(text: $appSearchText, prompt: "Search apps")
            .navigationTitle("Select App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        showAppPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Goal Type Picker

    private var goalTypePicker: some View {
        VStack(spacing: 12) {
            Text("What would you like to do?")
                .font(.headline)

            ForEach(GoalType.allCases, id: \.self) { type in
                TappableGlassCard(action: {
                    withAnimation(.glassSpring) { selectedType = type }
                    targetValue = defaultTargetValue(for: type)
                    if type == .reduceApp {
                        selectedApp = allAvailableApps.first ?? ""
                    }
                }) {
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundStyle(.blue)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.subheadline.weight(.medium))
                            Text(goalTypeDescription(for: type))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private func goalTypeDescription(for type: GoalType) -> String {
        switch type {
        case .reduceTotal: return "Limit your total daily screen time"
        case .reduceApp: return "Set a time limit for a specific app"
        case .increaseProductive: return "Spend more time on productive apps"
        case .reducePickups: return "Pick up your phone less often"
        case .noPhoneAfter: return "Set a bedtime for your phone"
        case .mindfulBreaks: return "Take regular breaks from screens"
        case .moodCheck: return "Check in with your mood daily"
        }
    }

    // MARK: - Goal Configurator

    private var goalConfigurator: some View {
        VStack(spacing: 24) {
            // Header
            GlassCard(style: .elevated) {
                HStack {
                    Image(systemName: selectedType?.icon ?? "target")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedType?.displayName ?? "")
                            .font(.title3.bold())
                        Text(goalTypeDescription(for: selectedType ?? .reduceTotal))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            appTargetPicker

            VStack(spacing: 8) {
                Text("Set Your Target")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Picker("Value", selection: $targetValue) {
                    switch selectedType {
                    case .reduceTotal:
                        ForEach([60, 90, 120, 150, 180, 210, 240, 300], id: \.self) { min in
                            Text("\(min / 60)h \(min % 60)m").tag(Double(min))
                        }
                    case .reduceApp:
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { min in
                            Text("\(min) min").tag(Double(min))
                        }
                    case .increaseProductive:
                        ForEach([30, 40, 50, 60, 70, 80], id: \.self) { pct in
                            Text("\(pct)%").tag(Double(pct))
                        }
                    case .reducePickups:
                        ForEach([20, 30, 40, 50, 60, 80, 100], id: \.self) { count in
                            Text("\(count) pickups").tag(Double(count))
                        }
                    case .noPhoneAfter:
                        ForEach([21, 22, 23, 0], id: \.self) { hour in
                            Text("\(hour):00").tag(Double(hour))
                        }
                    default:
                        Text("Daily").tag(1.0)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }

            GlassButton("Create Goal", style: .primary) {
                guard let type = selectedType else { return }
                let unit: GoalUnit
                switch type {
                case .reduceTotal, .reduceApp: unit = .minutes
                case .increaseProductive: unit = .percentage
                case .reducePickups: unit = .count
                case .noPhoneAfter: unit = .time
                default: unit = .count
                }

                let goal = UserGoal(
                    type: type,
                    targetValue: targetValue,
                    unit: unit,
                    relatedAppName: selectedApp.isEmpty ? nil : selectedApp
                )
                modelContext.insert(goal)
                dismiss()
            }
            .disabled(!canCreateGoal)
        }
    }

    @ViewBuilder
    private var appTargetPicker: some View {
        if selectedType == .reduceApp {
            VStack(alignment: .leading, spacing: 8) {
                Text("Target App:")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Button {
                    appSearchText = ""
                    customAppName = ""
                    showAppPicker = true
                } label: {
                    HStack {
                        if selectedApp.isEmpty {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Select an App")
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "app.fill")
                                .foregroundStyle(.blue)
                            Text(selectedApp)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                }
                .buttonStyle(LiquidGlassButtonStyle())
            }
        }
    }

    private var canCreateGoal: Bool {
        guard let type = selectedType else { return false }
        if type == .reduceApp {
            return !selectedApp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    // MARK: - Available Apps

    private var filteredAvailableApps: [String] {
        let query = appSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return allAvailableApps }
        return allAvailableApps.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private var filteredCommonApps: [String] {
        let query = appSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = Set(allAvailableApps)
        let common = Self.commonAppNames.filter { !existing.contains($0) }
        guard !query.isEmpty else { return common }
        return common.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private var allAvailableApps: [String] {
        var totalsByName: [String: TimeInterval] = [:]

        // Source 1: Historical DailyReports from SwiftData
        for report in reports.prefix(14) {
            for app in report.topApps {
                let name = displayName(for: app.appName, identifier: app.appIdentifier)
                guard !name.isEmpty else { continue }
                totalsByName[name, default: 0] += app.duration
            }
        }

        // Source 2-4: Shared daily data from all available transports
        let sharedSources: [SharedDailyData?] = [
            AppGroupManager.shared.load(forKey: UserDefaultsKeys.sharedLatestDailyData),
            loadDirectFile(),
            KeychainTransport.load()
        ]

        for source in sharedSources.compactMap({ $0 }) {
            for app in source.appUsages {
                let name = displayName(for: app.appName, identifier: app.appIdentifier)
                guard !name.isEmpty else { continue }
                totalsByName[name, default: 0] += app.duration
            }
        }

        return totalsByName
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .map(\.key)
    }

    /// Common app names as fallback when no usage data is available
    static let commonAppNames: [String] = [
        "Instagram", "TikTok", "YouTube", "Twitter", "Facebook",
        "Snapchat", "Reddit", "WhatsApp", "Telegram", "Messenger",
        "Safari", "Chrome", "Gmail", "Netflix", "Spotify",
        "Pinterest", "LinkedIn", "Discord", "Twitch", "BeReal"
    ]

    private func displayName(for appName: String, identifier: String) -> String {
        let name = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }

        let id = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return "" }

        let tail = id.split(separator: ".").last.map(String.init) ?? id
        return tail
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
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

    private func defaultTargetValue(for type: GoalType) -> Double {
        switch type {
        case .reduceTotal: return 180
        case .reduceApp: return 30
        case .increaseProductive: return 50
        case .reducePickups: return 40
        case .noPhoneAfter: return 23
        case .mindfulBreaks, .moodCheck: return 1
        }
    }
}
