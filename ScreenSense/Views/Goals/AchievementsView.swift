import SwiftUI

struct AchievementsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                achievementCard(icon: "medal.fill", title: "First Week", description: "Complete your first week of tracking", unlocked: true)
                achievementCard(icon: "flame.fill", title: "7-Day Warrior", description: "Hit your goal 7 days in a row", unlocked: false)
                achievementCard(icon: "clock.badge.checkmark", title: "Under 2 Hours", description: "Keep screen time under 2 hours for a day", unlocked: false)
                achievementCard(icon: "star.fill", title: "30-Day Legend", description: "Maintain a 30-day streak", unlocked: false)
                achievementCard(icon: "moon.fill", title: "Night Owl Cured", description: "No phone after bedtime for 7 days", unlocked: false)
                achievementCard(icon: "brain", title: "Mindful Master", description: "80% productive time for a full week", unlocked: false)
            }
            .padding()
        }
        .navigationTitle("Achievements")
    }
    
    private func achievementCard(icon: String, title: String, description: String, unlocked: Bool) -> some View {
        GlassCard(style: unlocked ? .elevated : .subtle) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(unlocked ? .yellow : .secondary)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if unlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
