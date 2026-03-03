import SwiftUI

struct TopAppsView: View {
    let apps: [AppUsageEntry]
    var onAppTap: ((AppUsageEntry) -> Void)?
    var limit: Int = 5
    
    var body: some View {
        VStack(spacing: 8) {
            if apps.isEmpty {
                Text("No usage data yet. Use a few apps, return to Home, and wait a moment for sync.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }

            ForEach(Array(apps.sorted(by: { $0.duration > $1.duration }).prefix(limit).enumerated()), id: \.element.appIdentifier) { index, entry in
                Button {
                    onAppTap?(entry)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: entry.category.icon)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text(entry.appName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(entry.duration.formattedShort)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                        
                        Text(entry.contentQuality.emoji)
                    }
                }
                .buttonStyle(.plain)
                
                if index < min(apps.count, limit) - 1 {
                    Divider()
                }
            }
        }
    }
}
