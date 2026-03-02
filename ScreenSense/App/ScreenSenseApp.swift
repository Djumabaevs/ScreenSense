import SwiftUI
import SwiftData

@main
struct ScreenSenseApp: App {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyReport.self,
            AppUsageEntry.self,
            Insight.self,
            UserGoal.self,
            MoodEntry.self,
            WeeklyDigest.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if onboardingCompleted {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
