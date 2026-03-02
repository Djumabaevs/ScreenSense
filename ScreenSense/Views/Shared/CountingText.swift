import SwiftUI

struct CountingText: View {
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(displayValue)))
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.6)) {
                    displayValue = newValue
                }
            }
    }
}
