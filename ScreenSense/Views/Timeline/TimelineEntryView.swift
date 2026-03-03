import SwiftUI

struct TimelineEntryView: View {
    let entry: AppUsageEntry
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: entry.category.icon)
                            .font(.title3)
                            .foregroundStyle(entry.contentQuality.color)
                            .frame(width: 32, height: 32)
                            .background(entry.contentQuality.color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.appName.isEmpty ? entry.appIdentifier.split(separator: ".").last.map(String.init) ?? "Unknown" : entry.appName)
                                .font(.headline)
                            Text("\(entry.duration.formattedShort) · \(entry.category.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(entry.contentQuality.emoji)
                            Text(entry.contentQuality.displayName)
                                .font(.caption2)
                                .foregroundStyle(entry.contentQuality.color)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }

                    ProgressBarView(
                        value: entry.duration,
                        total: 3600,
                        color: entry.contentQuality.color,
                        height: 6
                    )

                    if entry.contentQuality == .mindless && entry.duration > 1800 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("Long session without breaks")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
