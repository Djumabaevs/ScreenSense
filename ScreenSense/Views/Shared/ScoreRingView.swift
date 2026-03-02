import SwiftUI

struct ScoreRingView: View {
    let score: Int
    let size: CGFloat
    var lineWidth: CGFloat = 12
    var showLabel: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    private var progress: Double {
        Double(score) / 100.0
    }
    
    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 40 { return .orange }
        return .red
    }
    
    private var gradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [scoreColor.opacity(0.6), scoreColor]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * animatedProgress)
        )
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.ultraThinMaterial, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            if showLabel {
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: Double(score)))
                    
                    Text("/100")
                        .font(.system(size: size * 0.1, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
            if score >= 70 {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else if score < 40 {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
        .onChange(of: score) { _, _ in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    ScoreRingView(score: 78, size: 180)
}
