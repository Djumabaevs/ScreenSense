import Foundation
import SwiftData

@Model
final class Insight {
    var id: UUID
    var typeRaw: String
    var title: String
    var body: String
    var severityRaw: String
    var actionable: Bool
    var suggestedAction: String?
    var relatedApp: String?
    var date: Date
    var isRead: Bool
    var report: DailyReport?
    
    var type: InsightType {
        get { InsightType(rawValue: typeRaw) ?? .suggestion }
        set { typeRaw = newValue.rawValue }
    }
    
    var severity: InsightSeverity {
        get { InsightSeverity(rawValue: severityRaw) ?? .info }
        set { severityRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), type: InsightType = .suggestion, title: String = "", body: String = "", severity: InsightSeverity = .info, actionable: Bool = false, suggestedAction: String? = nil, relatedApp: String? = nil, date: Date = .now, isRead: Bool = false) {
        self.id = id
        self.typeRaw = type.rawValue
        self.title = title
        self.body = body
        self.severityRaw = severity.rawValue
        self.actionable = actionable
        self.suggestedAction = suggestedAction
        self.relatedApp = relatedApp
        self.date = date
        self.isRead = isRead
    }
}
