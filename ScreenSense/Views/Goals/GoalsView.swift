import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(filter: #Predicate<UserGoal> { $0.isActive }, sort: \UserGoal.createdAt) private var activeGoals: [UserGoal]
    @State private var showCreateGoal = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    activeGoalsSection
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("Goals")
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
            .sheet(isPresented: $showCreateGoal) {
                CreateGoalSheet()
                    .presentationDetents([.large])
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
                    GoalCardView(goal: goal)
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
                VStack(spacing: 8) {
                    achievementRow(icon: "medal.fill", title: "First Week", unlocked: true)
                    Divider()
                    achievementRow(icon: "flame.fill", title: "7-Day Streak", unlocked: activeGoals.contains { $0.streak >= 7 })
                    Divider()
                    achievementRow(icon: "clock.badge.checkmark", title: "Under 2h Day", unlocked: false)
                    Divider()
                    achievementRow(icon: "star.fill", title: "30-Day Streak", unlocked: false)
                    Divider()
                    achievementRow(icon: "moon.fill", title: "Night Owl Cured", unlocked: false)
                }
            }
        }
    }
    
    private func achievementRow(icon: String, title: String, unlocked: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(unlocked ? .yellow : .secondary)
            Text(title)
                .font(.subheadline)
            Spacer()
            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
}
