import Foundation

extension TimeInterval {
    var formattedShort: String {
        let totalMinutes = Int(self) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var formattedLong: String {
        let totalMinutes = Int(self) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) min"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "\(minutes) min"
    }
    
    var totalMinutes: Int {
        Int(self) / 60
    }
    
    var totalHours: Double {
        self / 3600.0
    }
}
