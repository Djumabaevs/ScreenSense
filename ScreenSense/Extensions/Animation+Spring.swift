import SwiftUI

extension Animation {
    static let glassSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let tabSwitch = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let scoreRing = Animation.easeOut(duration: 1.2)
    static let chartAnimation = Animation.easeInOut(duration: 0.8)
    static let cardStagger = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let moodPicker = Animation.spring(response: 0.4, dampingFraction: 0.75)
}
