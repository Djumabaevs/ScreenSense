import SwiftUI
import SwiftData

struct CreateGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedType: GoalType?
    @State private var targetValue: Double = 180
    @State private var selectedApp: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if selectedType == nil {
                    goalTypePicker
                } else {
                    goalConfigurator
                }
            }
            .padding()
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var goalTypePicker: some View {
        VStack(spacing: 12) {
            Text("What would you like to do?")
                .font(.headline)
            
            ForEach(GoalType.allCases, id: \.self) { type in
                Button {
                    withAnimation { selectedType = type }
                } label: {
                    GlassCard {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 32)
                            Text(type.displayName)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var goalConfigurator: some View {
        VStack(spacing: 24) {
            Text(selectedType?.displayName ?? "")
                .font(.title3.bold())
            
            VStack(spacing: 8) {
                Text("Target:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Picker("Value", selection: $targetValue) {
                    switch selectedType {
                    case .reduceTotal:
                        ForEach([60, 90, 120, 150, 180, 210, 240, 300], id: \.self) { min in
                            Text("\(min / 60)h \(min % 60)m").tag(Double(min))
                        }
                    case .reduceApp:
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { min in
                            Text("\(min) min").tag(Double(min))
                        }
                    case .increaseProductive:
                        ForEach([30, 40, 50, 60, 70, 80], id: \.self) { pct in
                            Text("\(pct)%").tag(Double(pct))
                        }
                    case .reducePickups:
                        ForEach([20, 30, 40, 50, 60, 80, 100], id: \.self) { count in
                            Text("\(count) pickups").tag(Double(count))
                        }
                    case .noPhoneAfter:
                        ForEach([21, 22, 23, 0], id: \.self) { hour in
                            Text("\(hour):00").tag(Double(hour))
                        }
                    default:
                        Text("Daily").tag(1.0)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }
            
            Spacer()
            
            GlassButton("Create Goal", style: .primary) {
                guard let type = selectedType else { return }
                let unit: GoalUnit
                switch type {
                case .reduceTotal, .reduceApp: unit = .minutes
                case .increaseProductive: unit = .percentage
                case .reducePickups: unit = .count
                case .noPhoneAfter: unit = .time
                default: unit = .count
                }
                
                let goal = UserGoal(
                    type: type,
                    targetValue: targetValue,
                    unit: unit,
                    relatedAppName: selectedApp.isEmpty ? nil : selectedApp
                )
                modelContext.insert(goal)
                dismiss()
            }
        }
    }
}
