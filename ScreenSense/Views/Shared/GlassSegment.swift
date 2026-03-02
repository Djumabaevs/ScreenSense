import SwiftUI

struct GlassSegment<T: Hashable>: View {
    let options: [(label: String, value: T)]
    @Binding var selection: T
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    let generator = UISelectionFeedbackGenerator()
                    generator.selectionChanged()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selection = option.value
                    }
                } label: {
                    Text(option.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selection == option.value ? .primary : .secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background {
                            if selection == option.value {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.regularMaterial)
                                    .matchedGeometryEffect(id: "segment", in: namespace)
                                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
