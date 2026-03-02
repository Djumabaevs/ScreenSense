import SwiftUI

struct HowItWorksView: View {
    let onContinue: () -> Void
    
    private let features: [(icon: String, title: String, description: String)] = [
        ("iphone", "Tracks What You Use", "We see which apps you open, not what's inside them"),
        ("brain", "AI Understands Why", "On-device AI classifies your usage patterns"),
        ("lightbulb.fill", "Gives You Insights", "Personalized tips, not generic advice"),
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("How ScreenSense Works")
                .font(.title2.bold())
            
            VStack(spacing: 16) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    GlassCard {
                        HStack(spacing: 16) {
                            Image(systemName: feature.icon)
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.title)
                                    .font(.headline)
                                Text(feature.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .springAppear(delay: Double(index) * 0.1)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            GlassButton("Continue", style: .primary, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
        }
    }
}
