import Foundation
import SwiftUI

struct Achievement: Identifiable {
    enum Metric {
        case recordingSessions
        case totalRecordingMinutes
        case vocabularyEntries
        case completedBooks
        case startedBooks
        case totalStars
        case longestRecordingMinutes
    }

    let id: String
    private let titleLocalizationKey: String
    private let detailLocalizationKey: String
    let iconSystemName: String
    let palette: [Color]
    let accentColor: Color
    let metric: Metric
    let targetValue: Double
    let progressFormatKey: String

    var title: LocalizedStringKey { LocalizedStringKey(titleLocalizationKey) }
    var detail: LocalizedStringKey { LocalizedStringKey(detailLocalizationKey) }

    func progress(for metrics: AchievementMetrics) -> AchievementProgress {
        AchievementProgress(
            achievement: self,
            currentValue: currentValue(for: metrics)
        )
    }

    private func currentValue(for metrics: AchievementMetrics) -> Double {
        switch metric {
        case .recordingSessions:
            return Double(metrics.recordingSessions)
        case .totalRecordingMinutes:
            return metrics.totalRecordingMinutes
        case .vocabularyEntries:
            return Double(metrics.vocabularyEntries)
        case .completedBooks:
            return Double(metrics.completedBooks)
        case .startedBooks:
            return Double(metrics.startedBooks)
        case .totalStars:
            return Double(metrics.totalStars)
        case .longestRecordingMinutes:
            return metrics.longestRecordingMinutes
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct AchievementMetrics {
    let recordingSessions: Int
    let totalRecordingMinutes: Double
    let vocabularyEntries: Int
    let completedBooks: Int
    let startedBooks: Int
    let totalStars: Int
    let longestRecordingMinutes: Double

    static let zero = AchievementMetrics(
        recordingSessions: 0,
        totalRecordingMinutes: 0,
        vocabularyEntries: 0,
        completedBooks: 0,
        startedBooks: 0,
        totalStars: 0,
        longestRecordingMinutes: 0
    )
}

struct AchievementProgress: Identifiable {
    let achievement: Achievement
    let currentValue: Double

    var id: String { achievement.id }

    var targetValue: Double { achievement.targetValue }

    var isUnlocked: Bool { currentValue >= targetValue }

    var completionFraction: Double {
        guard targetValue > 0 else { return 1 }
        return min(1, currentValue / targetValue)
    }

    var progressDescription: String {
        let currentDisplay: Int
        let targetDisplay: Int

        switch achievement.metric {
        case .totalRecordingMinutes, .longestRecordingMinutes:
            currentDisplay = Int(currentValue.rounded())
            targetDisplay = Int(targetValue.rounded())
        default:
            currentDisplay = Int(currentValue.rounded())
            targetDisplay = Int(targetValue.rounded())
        }

        let resource = LocalizedStringResource(achievement.progressFormatKey)
        return String(localized: resource, arguments: currentDisplay, targetDisplay)
    }
}
