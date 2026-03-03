import SwiftUI

/// Backward-compatible wrapper - the card content is now in GoalCardContent (GoalsView.swift).
struct GoalCardView: View {
    let goal: UserGoal

    var body: some View {
        GlassCard {
            GoalCardContent(goal: goal)
        }
    }
}
