import SwiftUI

struct GoalDetailView: View {
    let goal: UserGoal
    @Environment(\.dismiss) private var dismiss

    /// Screen-time goals get their live data from the extension, not SwiftData.
    private var isScreenTimeGoal: Bool {
        [.reduceTotal, .reduceApp, .increaseProductive, .reducePickups].contains(goal.type)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero card
                    GlassCard(style: .elevated) {
                        VStack(spacing: 16) {
                            Image(systemName: goal.type.icon)
                                .font(.largeTitle)
                                .foregroundStyle(.blue)

                            Text(goal.type.displayName)
                                .font(.title2.bold())

                            if isScreenTimeGoal {
                                // Live data — ring would show 0 because SwiftData isn't updated
                                liveProgressIndicator
                            } else {
                                ScoreRingView(score: Int(goal.progress * 100), size: 120, lineWidth: 10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Target card (screen-time goals show target details)
                    if isScreenTimeGoal {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Target")
                                    .font(.headline)

                                HStack {
                                    Text("Daily Limit")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(targetDescription)
                                        .bold()
                                }
                                .font(.subheadline)

                                if let app = goal.relatedAppName {
                                    HStack {
                                        Text("App")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(app)
                                            .bold()
                                    }
                                    .font(.subheadline)
                                }
                            }
                        }
                    }

                    // Stats card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stats")
                                .font(.headline)

                            HStack {
                                Text("Current Streak")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(goal.streak) days")
                                    .bold()
                            }
                            .font(.subheadline)

                            HStack {
                                Text("Best Streak")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(goal.bestStreak) days")
                                    .bold()
                            }
                            .font(.subheadline)

                            HStack {
                                Text("Created")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(goal.createdAt.dayMonthString)
                                    .bold()
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Live Progress Indicator (for screen-time goals)

    private var liveProgressIndicator: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: 0.001) // Minimal to show the ring outline
                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                    Text("Live")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.green)
                }
            }
            .frame(width: 120, height: 120)

            Text("Progress tracked live on Goals tab")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var targetDescription: String {
        switch goal.type {
        case .reduceTotal:
            return "Under \(Int(goal.targetValue)) minutes"
        case .reduceApp:
            return "Under \(Int(goal.targetValue)) minutes"
        case .increaseProductive:
            return "\(Int(goal.targetValue))% productive"
        case .reducePickups:
            return "Under \(Int(goal.targetValue)) pickups"
        default:
            return "\(Int(goal.targetValue)) \(goal.unit.rawValue)"
        }
    }
}
