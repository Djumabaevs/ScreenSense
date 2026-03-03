import SwiftUI

struct PrivacyPromiseView: View {
    let onContinue: () -> Void
    
    private let promises: [(String, String)] = [
        ("checkmark.shield.fill", "Everything runs on your iPhone"),
        ("xmark.icloud.fill", "No servers, no cloud, no tracking"),
        ("person.crop.circle.badge.xmark", "No account needed"),
        ("eye.slash.fill", "We can't see your data even if we wanted to"),
        ("trash.fill", "Delete anytime, it's truly gone"),
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            lockImage
            
            Text("Your Data Stays Yours")
                .font(.title2.bold())
            
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(promises.enumerated()), id: \.offset) { index, promise in
                        HStack(spacing: 12) {
                            Image(systemName: promise.0)
                                .foregroundStyle(.green)
                                .frame(width: 24)
                            
                            Text(promise.1)
                                .font(.subheadline)
                        }
                        .springAppear(delay: Double(index) * 0.08)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            GlassButton("I Love That. Next", style: .primary, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
        }
    }

    @ViewBuilder
    private var lockImage: some View {
        let baseImage = Image(systemName: "lock.shield.fill")
            .font(.system(size: 64))
            .foregroundStyle(.green.gradient)

        if #available(iOS 18.0, *) {
            baseImage.symbolEffect(.bounce, options: .nonRepeating)
        } else {
            baseImage
        }
    }
}
