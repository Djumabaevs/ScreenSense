import Foundation
import SwiftData

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Analysis Output

struct BrainAnalysis: Equatable {
    let overallAssessment: String
    let topStrength: String
    let topConcern: String
    let actionItems: [String]
    let moodInsight: String
    let scoreInterpretation: String
}

// MARK: - Analysis State

enum AIAnalysisState: Equatable {
    case idle
    case loading
    case completed(BrainAnalysis)
    case unavailable
    case error(String)
}

// MARK: - AI Analysis Engine

@Observable
final class AIAnalysisEngine {

    var analysisState: AIAnalysisState = .idle

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    // MARK: - Analyze

    @MainActor
    func analyze(report: DailyReport, moods: [MoodEntry]) async {
        // Guard: not enough data
        guard report.totalScreenTime >= 300 else {
            analysisState = .unavailable
            return
        }

        guard isAvailable else {
            analysisState = .unavailable
            return
        }

        analysisState = .loading

        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            await analyzeWithFoundationModels(report: report, moods: moods)
            return
        }
        #endif

        analysisState = .unavailable
    }

    func reset() {
        analysisState = .idle
    }

    // MARK: - Foundation Models Implementation

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    @MainActor
    private func analyzeWithFoundationModels(report: DailyReport, moods: [MoodEntry]) async {
        do {
            let instructions = Instructions(systemInstructions)
            let session = LanguageModelSession(instructions: instructions)
            let prompt = buildPrompt(report: report, moods: moods)

            let response = try await session.respond(to: prompt)
            let text = response.content

            let analysis = parseAnalysis(from: text, report: report)
            analysisState = .completed(analysis)
        } catch {
            analysisState = .error(error.localizedDescription)
        }
    }
    #endif

    // MARK: - Prompt Construction

    private var systemInstructions: String {
        """
        You are a friendly wellness coach analyzing someone's daily screen time data. \
        Be warm, encouraging, and honest. Reference specific numbers from their data. \
        Keep each section to 1-2 sentences maximum. \
        Focus on actionable improvements they can make tomorrow. \
        Never be harsh or judgmental.

        Respond in this exact format with these section headers:
        ASSESSMENT: (one sentence overall day summary)
        STRENGTH: (their best achievement today)
        CONCERN: (biggest area for improvement)
        ACTION1: (first specific actionable tip)
        ACTION2: (second specific actionable tip)
        ACTION3: (third specific actionable tip)
        MOOD: (observation connecting mood and screen time, or "none" if no mood data)
        SCORE: (what their wellness score means in plain language)
        """
    }

    private func buildPrompt(report: DailyReport, moods: [MoodEntry]) -> String {
        let totalMin = Int(report.totalScreenTime / 60)
        let prodMin = Int(report.productiveTime / 60)
        let neutralMin = Int(report.neutralTime / 60)
        let mindlessMin = Int(report.mindlessTime / 60)

        let prodPct = report.totalScreenTime > 0
            ? Int((report.productiveTime / report.totalScreenTime) * 100)
            : 0
        let mindlessPct = report.totalScreenTime > 0
            ? Int((report.mindlessTime / report.totalScreenTime) * 100)
            : 0

        let pickups = report.topApps.reduce(0) { $0 + $1.pickupCount }

        // Top 5 apps in compact format
        let topApps = report.topApps
            .sorted { $0.duration > $1.duration }
            .prefix(5)
            .map { "\($0.appName):\(Int($0.duration / 60))m(\($0.contentQuality.displayName.lowercased()))" }
            .joined(separator: ", ")

        // Mood context
        let moodStr: String
        if let latest = moods.first {
            let ctx = latest.context.map { ", context: \($0)" } ?? ""
            moodStr = "Mood: \(latest.moodLabel.displayName)\(ctx)"
        } else {
            moodStr = "Mood: no data"
        }

        let scoreLabel: String
        if report.score >= 80 { scoreLabel = "Great" }
        else if report.score >= 60 { scoreLabel = "Good" }
        else if report.score >= 40 { scoreLabel = "Fair" }
        else { scoreLabel = "Needs Attention" }

        return """
        Today's screen time: \(totalMin) minutes total. \
        Productive: \(prodMin)m (\(prodPct)%), Neutral: \(neutralMin)m, Mindless: \(mindlessMin)m (\(mindlessPct)%). \
        Wellness score: \(report.score)/100 (\(scoreLabel)). \
        Phone pickups: \(pickups). \
        Top apps: \(topApps). \
        \(moodStr). \
        Analyze this day and give personalized advice.
        """
    }

    // MARK: - Response Parsing

    private func parseAnalysis(from text: String, report: DailyReport) -> BrainAnalysis {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }

        func extract(_ prefix: String) -> String {
            if let line = lines.first(where: { $0.uppercased().hasPrefix(prefix.uppercased()) }) {
                let value = line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
                // Remove leading colon if present
                if value.hasPrefix(":") {
                    return String(value.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                return value
            }
            return ""
        }

        let assessment = extract("ASSESSMENT")
        let strength = extract("STRENGTH")
        let concern = extract("CONCERN")
        let action1 = extract("ACTION1")
        let action2 = extract("ACTION2")
        let action3 = extract("ACTION3")
        let mood = extract("MOOD")
        let score = extract("SCORE")

        let actions = [action1, action2, action3].filter { !$0.isEmpty }

        // Fallback if parsing fails — use the whole text as overall assessment
        if assessment.isEmpty && strength.isEmpty {
            return BrainAnalysis(
                overallAssessment: text.prefix(200).description,
                topStrength: "You tracked your screen time today — that's the first step!",
                topConcern: "Keep using the app to get more personalized insights.",
                actionItems: ["Try setting a daily screen time goal.", "Take a 5-minute break every hour."],
                moodInsight: "",
                scoreInterpretation: "Your wellness score is \(report.score)/100."
            )
        }

        return BrainAnalysis(
            overallAssessment: assessment,
            topStrength: strength,
            topConcern: concern,
            actionItems: actions.isEmpty ? ["Keep tracking your screen time for better insights!"] : actions,
            moodInsight: mood == "none" ? "" : mood,
            scoreInterpretation: score.isEmpty ? "Your wellness score is \(report.score)/100." : score
        )
    }
}
