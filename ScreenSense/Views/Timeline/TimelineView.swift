import SwiftUI
import SwiftData

enum TimelinePeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct TimelineView: View {
    @Query(sort: \DailyReport.date, order: .reverse) private var reports: [DailyReport]
    @State private var selectedPeriod: TimelinePeriod = .day
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                GlassSegment(
                    options: TimelinePeriod.allCases.map { ($0.rawValue, $0) },
                    selection: $selectedPeriod
                )
                .padding(.horizontal)
                
                dateNavigation
                
                ScrollView {
                    VStack(spacing: 0) {
                        switch selectedPeriod {
                        case .day:
                            DayTimelineView(
                                report: reportForDate(selectedDate),
                                date: selectedDate
                            )
                        case .week:
                            WeekHeatmapView(
                                reports: reportsForWeek(selectedDate),
                                weekStart: selectedDate.startOfWeek
                            )
                        case .month:
                            MonthCalendarView(
                                reports: reportsForMonth(selectedDate),
                                month: selectedDate
                            )
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Timeline")
        }
    }
    
    private var dateNavigation: some View {
        HStack {
            Button {
                withAnimation {
                    switch selectedPeriod {
                    case .day: selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                    case .week: selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
                    case .month: selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate)!
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )
            }

            Spacer()

            Text(dateLabel)
                .font(.headline)

            Spacer()

            Button {
                withAnimation {
                    switch selectedPeriod {
                    case .day: selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                    case .week: selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
                    case .month: selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)!
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Calendar.current.isDateInToday(selectedDate) ? .tertiary : .primary)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.12), lineWidth: 0.5)
                    )
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
        .padding(.horizontal)
    }
    
    private var dateLabel: String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .day:
            if Calendar.current.isDateInToday(selectedDate) { return "Today" }
            if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        case .week:
            let start = selectedDate.startOfWeek
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
            formatter.dateFormat = "MMM d"
            return "Week of \(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: selectedDate)
        }
    }
    
    private func reportForDate(_ date: Date) -> DailyReport? {
        reports.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private func reportsForWeek(_ date: Date) -> [DailyReport] {
        let start = date.startOfWeek
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        return reports.filter { $0.date >= start && $0.date < end }
    }
    
    private func reportsForMonth(_ date: Date) -> [DailyReport] {
        let start = date.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start)!
        return reports.filter { $0.date >= start && $0.date < end }
    }
}
