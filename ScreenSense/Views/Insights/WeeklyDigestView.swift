import SwiftUI

struct WeeklyDigestView: View {
    let digest: WeeklyDigest
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Week of \(digest.weekStart.dayMonthString)")
                            .font(.title2.bold())
                        
                        ScoreRingView(score: digest.averageScore, size: 140)
                        
                        if digest.comparedToLastWeek != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: digest.comparedToLastWeek > 0 ? "arrow.up" : "arrow.down")
                                Text("\(abs(Int(digest.comparedToLastWeek)))% from last week")
                            }
                            .font(.subheadline)
                            .foregroundStyle(digest.comparedToLastWeek > 0 ? .green : .red)
                        }
                    }
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time Breakdown")
                                .font(.headline)
                            
                            HStack {
                                Text("Total:")
                                    .foregroundStyle(.secondary)
                                Text(digest.totalScreenTime.formattedShort)
                                    .bold()
                            }
                            .font(.subheadline)
                            
                            HStack {
                                Text("Productive:")
                                    .foregroundStyle(.secondary)
                                Text("\(Int(digest.productivePercentage))%")
                                    .bold()
                                    .foregroundStyle(.green)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekly Summary")
                                .font(.headline)
                            Text(digest.topInsight)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Weekly Digest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
