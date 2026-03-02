import SwiftUI

struct ProgressBarView: View {
    let value: Double
    let total: Double
    let color: Color
    var height: CGFloat = 8
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(value / total, 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(.ultraThinMaterial)
                    .frame(height: height)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.gradient)
                    .frame(width: geometry.size.width * progress, height: height)
            }
        }
        .frame(height: height)
    }
}
