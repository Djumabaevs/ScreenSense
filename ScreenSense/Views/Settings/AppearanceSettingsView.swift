import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme = "System"
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    
    var body: some View {
        List {
            Section("Theme") {
                Picker("Theme", selection: $selectedTheme) {
                    Label("Light", systemImage: "sun.max.fill").tag("Light")
                    Label("Dark", systemImage: "moon.fill").tag("Dark")
                    Label("System", systemImage: "iphone").tag("System")
                }
                .pickerStyle(.segmented)
            }
            
            Section("Display") {
                Toggle("Haptic Feedback", isOn: $hapticEnabled)
                Toggle("Animations", isOn: $animationsEnabled)
            }
        }
        .navigationTitle("Appearance")
    }
}
