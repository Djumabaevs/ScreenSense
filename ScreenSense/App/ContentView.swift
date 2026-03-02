import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb.fill")
                }
                .tag(2)
            
            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}
