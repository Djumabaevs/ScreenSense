import SwiftUI

struct InsightDetailView: View {
    let insight: Insight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: insight.type.icon)
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(insight.title)
                                .font(.title2.bold())
                            Text(insight.severity.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    GlassCard {
                        Text(insight.body)
                            .font(.body)
                    }
                    
                    if let action = insight.suggestedAction {
                        GlassCard(style: .elevated) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Suggested Action", systemImage: "lightbulb.fill")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                                Text(action)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    if let app = insight.relatedApp {
                        GlassCard(style: .subtle) {
                            HStack {
                                Text("Related App:")
                                    .foregroundStyle(.secondary)
                                Text(app)
                                    .bold()
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
