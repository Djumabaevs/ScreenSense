import SwiftUI

struct InsightCardView: View {
    let insight: Insight
    @State private var isDismissed = false
    
    var body: some View {
        if !isDismissed {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: insight.type.icon)
                            .foregroundStyle(.blue)
                        Text(insight.title)
                            .font(.headline)
                        Spacer()
                        Text(insight.severity.emoji)
                    }
                    
                    Text(insight.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let action = insight.suggestedAction {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                            Text("Try: \(action)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        GlassButton("Got it", style: .secondary) {
                            withAnimation {
                                insight.isRead = true
                                isDismissed = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        GlassButton("More", style: .ghost) {}
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}
