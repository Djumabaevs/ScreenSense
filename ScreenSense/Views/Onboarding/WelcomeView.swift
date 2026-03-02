import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.pulse, options: .repeating)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            VStack(spacing: 12) {
                Text("ScreenSense")
                    .font(.largeTitle.bold())
                
                Text("Understand your screen time,\nnot just count it")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                GlassButton("Get Started", style: .primary, action: onContinue)
                
                Button("Already have data?") {}
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
    }
}
