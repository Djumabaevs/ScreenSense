import SwiftUI
import SwiftData

struct MoodCheckSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMood: MoodLabel?
    @State private var context: String = ""
    @State private var selectedTags: Set<String> = []
    
    private let tags = ["Working", "Social", "Bored", "Reading", "Gaming", "Rest"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("How are you feeling?")
                    .font(.title2.bold())
                
                HStack(spacing: 16) {
                    ForEach(MoodLabel.allCases, id: \.self) { mood in
                        Button {
                            withAnimation(.moodPicker) {
                                selectedMood = mood
                            }
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                        } label: {
                            Text(mood.emoji)
                                .font(.system(size: selectedMood == mood ? 44 : 32))
                                .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                                .opacity(selectedMood == nil || selectedMood == mood ? 1.0 : 0.4)
                        }
                    }
                }
                
                if selectedMood != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What were you doing?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Just scrolling...", text: $context)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Quick tags:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Button {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                } label: {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedTags.contains(tag) ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                
                if let mood = selectedMood {
                    GlassButton("Save Mood", style: .primary) {
                        let entry = MoodEntry(
                            mood: mood.value,
                            moodLabel: mood,
                            context: context.isEmpty ? nil : context,
                            linkedApps: Array(selectedTags)
                        )
                        modelContext.insert(entry)
                        dismiss()
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
