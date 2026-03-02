import Foundation
import SwiftData

final class DataExportService {
    static let shared = DataExportService()
    
    struct ExportData: Codable {
        let exportDate: Date
        let reports: [ExportReport]
    }
    
    struct ExportReport: Codable {
        let date: Date
        let totalScreenTime: TimeInterval
        let productiveTime: TimeInterval
        let neutralTime: TimeInterval
        let mindlessTime: TimeInterval
        let score: Int
        let apps: [ExportApp]
    }
    
    struct ExportApp: Codable {
        let name: String
        let category: String
        let duration: TimeInterval
        let quality: String
    }
    
    func exportJSON(reports: [DailyReport]) throws -> Data {
        let exportReports = reports.map { report in
            ExportReport(
                date: report.date,
                totalScreenTime: report.totalScreenTime,
                productiveTime: report.productiveTime,
                neutralTime: report.neutralTime,
                mindlessTime: report.mindlessTime,
                score: report.score,
                apps: report.topApps.map { app in
                    ExportApp(
                        name: app.appName,
                        category: app.categoryRaw,
                        duration: app.duration,
                        quality: app.contentQualityRaw
                    )
                }
            )
        }
        
        let exportData = ExportData(exportDate: .now, reports: exportReports)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }
    
    func exportCSV(reports: [DailyReport]) -> String {
        var csv = "Date,Total Screen Time (min),Productive (min),Neutral (min),Mindless (min),Score\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for report in reports {
            let line = "\(dateFormatter.string(from: report.date)),\(Int(report.totalScreenTime / 60)),\(Int(report.productiveTime / 60)),\(Int(report.neutralTime / 60)),\(Int(report.mindlessTime / 60)),\(report.score)"
            csv += line + "\n"
        }
        
        return csv
    }
}
