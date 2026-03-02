import SwiftUI
import SwiftData

@Observable
final class AppState {
    var currentScore: Int = 0
    var todayScreenTime: TimeInterval = 0

    func refreshState(modelContext: ModelContext) {
        let today = Date().startOfDay
        let descriptor = FetchDescriptor<DailyReport>(
            predicate: #Predicate { $0.date >= today }
        )

        if let report = try? modelContext.fetch(descriptor).first {
            currentScore = report.score
            todayScreenTime = report.totalScreenTime
        }
    }
}
