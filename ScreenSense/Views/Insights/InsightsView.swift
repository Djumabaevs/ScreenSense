import SwiftUI
import SwiftData
import DeviceActivity

struct InsightsView: View {
    @Query(sort: \Insight.date, order: .reverse) private var insights: [Insight]
    @Query(sort: \WeeklyDigest.weekStart, order: .reverse) private var digests: [WeeklyDigest]
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]
    @State private var showWeeklyDigest = false
    @State private var showBrainSheet = false
    @State private var reportRefreshID = UUID()

    private var filterForToday: DeviceActivityFilter {
        let now = Date()
        let interval = DateInterval(
            start: Calendar.current.startOfDay(for: now),
            end: now
        )
        return DeviceActivityFilter(
            segment: .hourly(during: interval),
            users: .all,
            devices: .all
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly digest card (if available from SwiftData)
                    if let digest = digests.first {
                        weeklyDigestCard(digest)
                    }

                    // Live insights from DeviceActivityReport
                    insightsReportSection

                    // Patterns section
                    patternsSection
                }
                .padding()
                .padding(.bottom, 32)
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showBrainSheet = true
                    } label: {
                        Image(systemName: "brain.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showWeeklyDigest) {
                if let digest = digests.first {
                    WeeklyDigestView(digest: digest)
                }
            }
            .sheet(isPresented: $showBrainSheet) {
                BrainAnalysisSheet()
            }
        }
    }

    // MARK: - Insights Report Section

    @ViewBuilder
    private var insightsReportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today's Insights", systemImage: "sparkles")
                    .font(.headline)

                Spacer()

                Button {
                    reportRefreshID = UUID()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.10), lineWidth: 0.5)
                        )
                }
            }

            DeviceActivityReport(.insights, filter: filterForToday)
                .id(reportRefreshID)
                .frame(minHeight: 600)
                .overlay {
                    Color.white.opacity(0.001)
                }
        }
    }

    // MARK: - Patterns Section

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns")
                .font(.headline)

            if let correlation = MoodAnalyzer.shared.moodScreenTimeCorrelation(moods: moods, reports: reports) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mood + Usage", systemImage: "face.smiling")
                            .font(.subheadline.bold())
                        Text(correlation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GlassCard {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.blue.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Usage Patterns")
                            .font(.subheadline.bold())
                        Text("Keep using the app to discover your peak hours and usage trends.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            GlassCard {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(.green.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Trends")
                            .font(.subheadline.bold())
                        Text("After a few days, you'll see how your screen time changes over the week.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Weekly Digest Card

    private func weeklyDigestCard(_ digest: WeeklyDigest) -> some View {
        Button {
            showWeeklyDigest = true
        } label: {
            GlassCard(style: .elevated) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Weekly Digest", systemImage: "doc.text.fill")
                            .font(.headline)
                        Text(digest.topInsight)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Tap to see full report")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .springAppear()
    }
}

// MARK: - Brain Analysis Sheet

struct BrainAnalysisSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var filterForToday: DeviceActivityFilter {
        let now = Date()
        let interval = DateInterval(
            start: Calendar.current.startOfDay(for: now),
            end: now
        )
        return DeviceActivityFilter(
            segment: .hourly(during: interval),
            users: .all,
            devices: .all
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.purple.opacity(0.25), .blue.opacity(0.15), .clear],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "brain.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .purple.opacity(0.3), radius: 8, y: 2)
                        }

                        Text("Deep Analysis")
                            .font(.title2.bold())

                        Text("Your complete screen time breakdown and personalized recommendations.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.20), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: .purple.opacity(0.08), radius: 16, y: 6)

                    // Full dashboard report
                    DeviceActivityReport(.totalActivity, filter: filterForToday)
                        .frame(minHeight: 800)
                        .overlay {
                            Color.white.opacity(0.001)
                        }

                    // Tips section
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Wellness Tips", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)

                            tipRow(icon: "moon.fill", color: .indigo, text: "Stop screens 1 hour before bed for better sleep quality.")
                            tipRow(icon: "timer", color: .orange, text: "Use the Pomodoro technique: 25 min focused work, 5 min break.")
                            tipRow(icon: "bell.slash.fill", color: .red, text: "Turn off non-essential notifications to reduce pickups.")
                            tipRow(icon: "eye", color: .teal, text: "Follow the 20-20-20 rule to reduce eye strain.")
                            tipRow(icon: "figure.walk", color: .green, text: "Take a 5-minute walk for every hour of screen time.")
                        }
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
            .navigationTitle("Brain Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func tipRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
