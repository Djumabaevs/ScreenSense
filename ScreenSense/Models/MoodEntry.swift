import Foundation
import SwiftData

@Model
final class MoodEntry {
    var id: UUID
    var date: Date
    var mood: Float
    var moodLabelRaw: String
    var context: String?
    var linkedApps: [String]
    
    var moodLabel: MoodLabel {
        get { MoodLabel(rawValue: moodLabelRaw) ?? .okay }
        set { moodLabelRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), date: Date = .now, mood: Float = 0.5, moodLabel: MoodLabel = .okay, context: String? = nil, linkedApps: [String] = []) {
        self.id = id
        self.date = date
        self.mood = mood
        self.moodLabelRaw = moodLabel.rawValue
        self.context = context
        self.linkedApps = linkedApps
    }
}
