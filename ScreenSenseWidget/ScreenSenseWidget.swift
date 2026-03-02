import WidgetKit
import SwiftUI

struct ScreenSenseEntry: TimelineEntry {
    let date: Date
    let score: Int
    let totalScreenTime: TimeInterval
    let productivePercentage: Double
    let topAppName: String
    let topAppTime: TimeInterval
    let isOnTrack: Bool
}

struct ScreenSenseProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScreenSenseEntry {
        ScreenSenseEntry(date: .now, score: 78, totalScreenTime: 8040, productivePercentage: 38, topAppName: "Instagram", topAppTime: 3120, isOnTrack: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ScreenSenseEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScreenSenseEntry>) -> Void) {
        let entry = placeholder(in: context)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct SmallWidgetView: View {
    let entry: ScreenSenseEntry
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: Double(entry.score) / 100.0)
                    .stroke(
                        Color.scoreColor(for: entry.score).gradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(entry.score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            
            Text("Today")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(entry.totalScreenTime.formattedShort)
                .font(.caption.bold())
            
            HStack(spacing: 2) {
                Circle()
                    .fill(entry.isOnTrack ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                Text(entry.isOnTrack ? "On track" : "Over goal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: ScreenSenseEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: Double(entry.score) / 100.0)
                        .stroke(
                            Color.scoreColor(for: entry.score).gradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(entry.score)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                
                Text(entry.totalScreenTime.formattedShort)
                    .font(.caption.bold())
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Today's Top")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "iphone")
                        .font(.caption2)
                    Text(entry.topAppName)
                        .font(.caption)
                    Spacer()
                    Text(entry.topAppTime.formattedShort)
                        .font(.caption.monospacedDigit())
                }
                
                HStack(spacing: 2) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("\(Int(entry.productivePercentage))% productive")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct ScreenSenseWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScreenSenseSmallWidget()
        ScreenSenseMediumWidget()
    }
}

struct ScreenSenseSmallWidget: Widget {
    let kind: String = "ScreenSenseSmall"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScreenSenseProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Screen Score")
        .description("Your daily screen health score at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct ScreenSenseMediumWidget: Widget {
    let kind: String = "ScreenSenseMedium"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScreenSenseProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Screen Summary")
        .description("Score and top apps for today.")
        .supportedFamilies([.systemMedium])
    }
}
