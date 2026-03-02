import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomeView(onContinue: { withAnimation { currentPage = 1 } })
                .tag(0)
            HowItWorksView(onContinue: { withAnimation { currentPage = 2 } })
                .tag(1)
            PrivacyPromiseView(onContinue: { withAnimation { currentPage = 3 } })
                .tag(2)
            PermissionsSetupView(onComplete: { onboardingCompleted = true })
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
    }
}
