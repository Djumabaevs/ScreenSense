import SwiftUI
import SwiftData
import DeviceActivity

struct GoalsView: View {
    @Query(filter: #Predicate<UserGoal> { $0.isActive }, sort: \UserGoal.createdAt) private var activeGoals: [UserGoal]
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @Environment(\.modelContext) private var modelContext
    @State private var showCreateGoal = false
    @State private var showGoalDetail: UserGoal?
    @State private var showAchievementDetail: Achievement?
    @State private var reportRefreshID = UUID()
    @State private var goalDataRefreshID = UUID()

    /// Filter for DeviceActivityReport — today's data
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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Live progress header from extension (outside ScrollView so it sizes correctly)
                // DeviceActivityReport has no intrinsic height inside ScrollView — mirrors Dashboard pattern.
                if !activeGoals.isEmpty {
                    DeviceActivityReport(.goalProgress, filter: filterForToday)
                        .id(goalDataRefreshID)
                }

                // Scrollable native content: interactive goal cards + achievements
                ScrollView {
                    VStack(spacing: 20) {
                        activeGoalsSection
                        achievementsSection
                    }
                    .padding()
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Goals")
            .onAppear {
                // Save goal definitions to shared storage so extension can read them
                saveGoalDefinitionsToSharedStorage()

                // Restart monitoring with goal-based thresholds + schedule notifications
                ScreenTimeService.shared.startMonitoringIfAuthorized()
                ScreenTimeService.shared.scheduleGoalNotifications()

                // Refresh ID to re-render the extension report
                goalDataRefreshID = UUID()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateGoal, onDismiss: {
                // New goal may have been created — update shared storage & monitoring
                saveGoalDefinitionsToSharedStorage()
                ScreenTimeService.shared.startMonitoringIfAuthorized()
                ScreenTimeService.shared.scheduleGoalNotifications()
                goalDataRefreshID = UUID()
            }) {
                CreateGoalSheet()
                    .presentationDetents([.large])
            }
            .sheet(item: $showGoalDetail) { goal in
                GoalDetailView(goal: goal)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $showAchievementDetail) { achievement in
                AchievementDetailSheet(achievement: achievement)
                    .presentationDetents([.medium])
            }
        }
    }

    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Goals")
                .font(.headline)

            if activeGoals.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Goals Yet",
                    message: "Set your first goal to start tracking your progress.",
                    actionTitle: "Create Goal"
                ) {
                    showCreateGoal = true
                }
            } else {
                ForEach(Array(activeGoals.enumerated()), id: \.element.id) { index, goal in
                    TappableGlassCard(action: { showGoalDetail = goal }) {
                        GoalCardContent(goal: goal)
                    }
                    .springAppear(delay: Double(index) * 0.05)
                }
            }
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)

            GlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(allAchievements.enumerated()), id: \.element.id) { index, achievement in
                        Button {
                            showAchievementDetail = achievement
                        } label: {
                            HStack {
                                Image(systemName: achievement.icon)
                                    .foregroundStyle(achievement.unlocked ? .yellow : .secondary)
                                Text(achievement.title)
                                    .font(.subheadline)
                                Spacer()
                                if achievement.unlocked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(LiquidGlassButtonStyle())

                        if index < allAchievements.count - 1 {
                            Divider().opacity(0.3)
                        }
                    }
                }
            }
        }
    }

    private var allAchievements: [Achievement] {
        let hasUnder2h = reports.contains { $0.totalScreenTime < 2 * 3600 }

        let installDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.installationDate) as? Date ?? Date()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        let firstWeekUnlocked = daysSinceInstall >= 7

        let nightOwlCured = activeGoals.contains { $0.type == .noPhoneAfter && $0.streak >= 7 }

        return [
            Achievement(icon: "medal.fill", title: "First Week", unlocked: firstWeekUnlocked, description: "Use ScreenSense for 7 consecutive days.", howTo: "Keep opening the app daily to track your screen time."),
            Achievement(icon: "flame.fill", title: "7-Day Streak", unlocked: activeGoals.contains { $0.streak >= 7 }, description: "Maintain a 7-day streak on any goal.", howTo: "Set an achievable daily goal and stick to it for a week."),
            Achievement(icon: "clock.badge.checkmark", title: "Under 2h Day", unlocked: hasUnder2h, description: "Have a day with less than 2 hours of total screen time.", howTo: "Try a digital detox day — read a book, go outside, or meet friends."),
            Achievement(icon: "star.fill", title: "30-Day Streak", unlocked: activeGoals.contains { $0.streak >= 30 }, description: "Maintain a 30-day streak on any goal.", howTo: "Consistency is key. Keep meeting your daily target for a full month."),
            Achievement(icon: "moon.fill", title: "Night Owl Cured", unlocked: nightOwlCured, description: "No phone usage after your bedtime for 7 consecutive days.", howTo: "Set a Bedtime Boundary goal and keep your phone in another room at night.")
        ]
    }

    // MARK: - Goal Definitions for Extension

    /// Saves goal definitions to shared storage so the extension can read them
    /// and calculate goal progress directly during report rendering.
    private func saveGoalDefinitionsToSharedStorage() {
        let defs = activeGoals.map { goal in
            SharedGoalDefinition(
                id: goal.id.uuidString,
                typeRaw: goal.typeRaw,
                targetValue: goal.targetValue,
                relatedAppName: goal.relatedAppName,
                currentStreak: goal.streak,
                bestStreak: goal.bestStreak
            )
        }

        // Save via AppGroupManager
        AppGroupManager.shared.save(defs, forKey: "goalDefinitions")

        // Also save directly to file (more reliable cross-process)
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupID) {
            let fileURL = containerURL.appendingPathComponent("goal_definitions.json")
            if let encoded = try? JSONEncoder().encode(defs) {
                try? encoded.write(to: fileURL, options: .atomic)
                print("[GoalsView] Saved \(defs.count) goal definitions to shared container")
            }
        }
    }

}

// MARK: - Goal Card Content (extracted for TappableGlassCard)

struct GoalCardContent: View {
    let goal: UserGoal

    /// Screen-time goals depend on extension data; their progress is shown in the Live header.
    private var isScreenTimeGoal: Bool {
        [.reduceTotal, .reduceApp, .increaseProductive, .reducePickups].contains(goal.type)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: icon + name
            HStack {
                Image(systemName: goal.type.icon)
                    .foregroundStyle(.blue)
                Text(goal.type.displayName)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }

            // Description
            if let app = goal.relatedAppName {
                Text("Under \(Int(goal.targetValue)) min for \(app)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(goalDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress section: live indicator for screen-time goals, actual values for local goals
            if isScreenTimeGoal {
                // Screen-time goals — progress is shown in the Live Progress header above
                HStack(spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.green)
                    Text("Live progress tracked above")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                // Local goals (mindfulBreaks, moodCheck, noPhoneAfter) — show actual values
                HStack {
                    Text(progressLabel)
                        .font(.subheadline.monospacedDigit())
                    Spacer()
                }

                ProgressBarView(
                    value: goal.currentValue,
                    total: goal.targetValue,
                    color: progressColor
                )
            }

            // Footer: streak + status
            HStack {
                if goal.streak > 0 {
                    Label("\(goal.streak) day streak", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                goalStatusLabel
            }
        }
    }

    private var goalDescription: String {
        switch goal.type {
        case .reduceTotal:
            return "Under \(Int(goal.targetValue)) minutes daily"
        case .increaseProductive:
            return "\(Int(goal.targetValue))% productive time"
        case .reducePickups:
            return "Under \(Int(goal.targetValue)) pickups daily"
        case .noPhoneAfter:
            return "No phone after \(Int(goal.targetValue)):00"
        case .mindfulBreaks:
            return "Take mindful breaks daily"
        case .moodCheck:
            return "Check in with your mood daily"
        default:
            return goal.type.displayName
        }
    }

    private var progressLabel: String {
        switch goal.type {
        case .noPhoneAfter:
            let hour = Int(goal.targetValue)
            return "No phone after \(hour):00"
        case .mindfulBreaks:
            return "\(Int(goal.currentValue)) / \(Int(goal.targetValue)) breaks"
        case .moodCheck:
            return goal.currentValue >= 1 ? "Checked in today" : "Not checked in"
        default:
            // Screen-time goals won't reach here (hidden by isScreenTimeGoal)
            return goal.type.displayName
        }
    }

    private var progressColor: Color {
        if GoalTracker.shared.isGoalMet(goal) { return .green }
        if goal.progress > 0.8 { return .orange }
        return .blue
    }

    @ViewBuilder
    private var goalStatusLabel: some View {
        switch goal.type {
        case .noPhoneAfter:
            Text("Active reminder")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .mindfulBreaks:
            if goal.currentValue >= goal.targetValue {
                Label("Done!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Take a break today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .moodCheck:
            if GoalTracker.shared.isGoalMet(goal) {
                Label("Checked in!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Log your mood today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        default:
            // Screen-time goals: show target info instead of misleading 0 remaining
            if isScreenTimeGoal {
                Label("Target: \(Int(goal.targetValue)) \(goal.unit.rawValue)", systemImage: "target")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if GoalTracker.shared.isGoalMet(goal) {
                Label("Complete!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                let remaining = GoalTracker.shared.remainingForGoal(goal)
                Text("\(Int(remaining)) \(goal.unit.rawValue) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Achievement Model

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let unlocked: Bool
    let description: String
    let howTo: String
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(style: .elevated) {
                        VStack(spacing: 16) {
                            Image(systemName: achievement.icon)
                                .font(.system(size: 48))
                                .foregroundStyle(achievement.unlocked ? .yellow : .secondary)
                                .frame(width: 80, height: 80)
                                .background(
                                    (achievement.unlocked ? Color.yellow : Color.gray).opacity(0.12),
                                    in: Circle()
                                )

                            Text(achievement.title)
                                .font(.title2.bold())

                            if achievement.unlocked {
                                Label("Unlocked", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            } else {
                                Label("Locked", systemImage: "lock.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Description", systemImage: "info.circle")
                                .font(.headline)
                            Text(achievement.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !achievement.unlocked {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("How to Unlock", systemImage: "lightbulb.fill")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                                Text(achievement.howTo)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
