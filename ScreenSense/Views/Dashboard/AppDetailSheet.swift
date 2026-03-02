import SwiftUI

struct AppDetailSheet: View {
    let entry: AppUsageEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    contentQualitySection
                    usagePatternSection
                    actionsSection
                }
                .padding()
            }
            .navigationTitle(entry.appName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: entry.category.icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .frame(width: 60, height: 60)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.appName)
                    .font(.title2.bold())
                Text("\(entry.category.displayName) · \(entry.duration.formattedShort) today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var contentQualitySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Content Quality")
                    .font(.headline)
                
                HStack {
                    Text(entry.contentQuality.emoji)
                    Text(entry.contentQuality.displayName)
                        .font(.title3.bold())
                        .foregroundStyle(entry.contentQuality.color)
                }
                
                Text(qualityDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var usagePatternSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Usage Pattern")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Sessions: \(entry.pickupCount)", systemImage: "arrow.clockwise")
                        Label("Longest: \(entry.longestSession.formattedShort)", systemImage: "timer")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var actionsSection: some View {
        GlassCard {
            VStack(spacing: 12) {
                actionRow(icon: "timer", title: "Set Daily Limit")
                Divider()
                actionRow(icon: "bell.slash", title: "Mute Notifications")
                Divider()
                actionRow(icon: "pin", title: "Pin to Dashboard")
                Divider()
                actionRow(icon: "eye.slash", title: "Exclude from Score")
            }
        }
    }
    
    private func actionRow(icon: String, title: String) -> some View {
        Button {
        } label: {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
    }
    
    private var qualityDescription: String {
        switch entry.contentQuality {
        case .productive:
            return "This session was focused and productive. Great use of your time!"
        case .neutral:
            return "A balanced session — not particularly productive or wasteful."
        case .mindless:
            return "Based on your usage pattern: long continuous scrolling with rare interactions."
        }
    }
}

extension AppUsageEntry: @retroactive Identifiable {
    public var id: String { appIdentifier + date.description }
}
