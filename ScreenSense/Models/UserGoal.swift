import Foundation
import SwiftData

@Model
final class UserGoal {
    var id: UUID
    var typeRaw: String
    var targetValue: Double
    var currentValue: Double
    var unitRaw: String
    var frequencyRaw: String
    var isActive: Bool
    var createdAt: Date
    var streak: Int
    var bestStreak: Int
    var relatedAppName: String?
    
    var type: GoalType {
        get { GoalType(rawValue: typeRaw) ?? .reduceTotal }
        set { typeRaw = newValue.rawValue }
    }
    
    var unit: GoalUnit {
        get { GoalUnit(rawValue: unitRaw) ?? .minutes }
        set { unitRaw = newValue.rawValue }
    }
    
    var frequency: GoalFrequency {
        get { GoalFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    init(id: UUID = UUID(), type: GoalType = .reduceTotal, targetValue: Double = 0, currentValue: Double = 0, unit: GoalUnit = .minutes, frequency: GoalFrequency = .daily, isActive: Bool = true, createdAt: Date = .now, streak: Int = 0, bestStreak: Int = 0, relatedAppName: String? = nil) {
        self.id = id
        self.typeRaw = type.rawValue
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unitRaw = unit.rawValue
        self.frequencyRaw = frequency.rawValue
        self.isActive = isActive
        self.createdAt = createdAt
        self.streak = streak
        self.bestStreak = bestStreak
        self.relatedAppName = relatedAppName
    }
}
