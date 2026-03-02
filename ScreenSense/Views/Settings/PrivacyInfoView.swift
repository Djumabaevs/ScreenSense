import SwiftUI

struct PrivacyInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GlassCard(style: .elevated) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        
                        Text("Your Privacy is Absolute")
                            .font(.title3.bold())
                        
                        Text("ScreenSense was designed from the ground up to protect your data.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                privacyItem(icon: "iphone", title: "On-Device Only", description: "All data processing happens on your iPhone. Nothing leaves your device.")
                privacyItem(icon: "xmark.icloud", title: "No Servers", description: "We don't have servers. There's nowhere for your data to go.")
                privacyItem(icon: "person.crop.circle.badge.xmark", title: "No Account", description: "No sign-up, no login, no tracking. Just install and use.")
                privacyItem(icon: "eye.slash", title: "No Content Access", description: "We see WHICH apps you use, not WHAT you do inside them.")
                privacyItem(icon: "trash", title: "Full Control", description: "Delete all data anytime. When it's gone, it's truly gone.")
                privacyItem(icon: "chart.bar.xaxis", title: "No Analytics", description: "No Firebase, no Mixpanel, no tracking SDKs of any kind.")
            }
            .padding()
        }
        .navigationTitle("Privacy")
    }
    
    private func privacyItem(icon: String, title: String, description: String) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.green)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
