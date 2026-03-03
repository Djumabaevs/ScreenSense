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

        let fileManager = FileManager.default
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let storeDirectory = applicationSupport.appendingPathComponent("ScreenSense", isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("default.store")

        do {
            try fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        } catch {
            print("[ScreenSenseApp] Failed to create store directory: \(error)")
        }

        let modelConfiguration = ModelConfiguration(
            "default",
            schema: schema,
            url: storeURL
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.installationDate) == nil {
            UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.installationDate)
        }
    }

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
