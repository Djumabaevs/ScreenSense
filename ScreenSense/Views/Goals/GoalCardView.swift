import SwiftUI

struct GoalCardView: View {
    let goal: UserGoal
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: goal.type.icon)
                        .foregroundStyle(.blue)
                    Text(goal.type.displayName)
                        .font(.headline)
                    Spacer()
                }
                
                if let app = goal.relatedAppName {
                    Text("Under \(Int(goal.targetValue)) min for \(app)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(goalDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
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
                
                HStack {
                    if goal.streak > 0 {
                        Label("\(goal.streak) day streak", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    Spacer()
                    
                    let remaining = GoalTracker.shared.remainingForGoal(goal)
                    if remaining > 0 {
                        Text("\(Int(remaining)) \(goal.unit.rawValue) remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Complete!", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
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
        default:
            return goal.type.displayName
        }
    }
    
    private var progressLabel: String {
        switch goal.type {
        case .reduceTotal, .reduceApp:
            return "\(Int(goal.currentValue))m / \(Int(goal.targetValue))m"
        case .increaseProductive:
            return "\(Int(goal.currentValue))% / \(Int(goal.targetValue))%"
        case .reducePickups:
            return "\(Int(goal.currentValue)) / \(Int(goal.targetValue))"
        default:
            return "\(Int(goal.currentValue)) / \(Int(goal.targetValue))"
        }
    }
    
    private var progressColor: Color {
        if GoalTracker.shared.isGoalMet(goal) { return .green }
        if goal.progress > 0.8 { return .orange }
        return .blue
    }
}
