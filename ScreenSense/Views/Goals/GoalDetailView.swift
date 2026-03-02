import SwiftUI

struct GoalDetailView: View {
    let goal: UserGoal
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    GlassCard(style: .elevated) {
                        VStack(spacing: 16) {
                            Image(systemName: goal.type.icon)
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                            
                            Text(goal.type.displayName)
                                .font(.title2.bold())
                            
                            ScoreRingView(score: Int(goal.progress * 100), size: 120, lineWidth: 10)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
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
}
