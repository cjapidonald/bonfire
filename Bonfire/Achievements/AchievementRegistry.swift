import SwiftUI

enum AchievementRegistry {
    static let all: [Achievement] = [
        Achievement(
            id: "first-echo",
            titleLocalizationKey: "achievement.firstEcho.title",
            detailLocalizationKey: "achievement.firstEcho.detail",
            iconSystemName: "mic.circle.fill",
            palette: [
                Color(red: 0.38, green: 0.67, blue: 0.93),
                Color(red: 0.15, green: 0.37, blue: 0.82)
            ],
            accentColor: DesignColor.aquaGlow,
            metric: .recordingSessions,
            targetValue: 1,
            progressFormatKey: "achievements.progress.sessions"
        ),
        Achievement(
            id: "steady-train",
            titleLocalizationKey: "achievement.steadyTrain.title",
            detailLocalizationKey: "achievement.steadyTrain.detail",
            iconSystemName: "arrow.clockwise.circle.fill",
            palette: [
                Color(red: 0.99, green: 0.75, blue: 0.39),
                Color(red: 0.90, green: 0.48, blue: 0.16)
            ],
            accentColor: DesignColor.amberGlow,
            metric: .recordingSessions,
            targetValue: 10,
            progressFormatKey: "achievements.progress.sessions"
        ),
        Achievement(
            id: "word-collector",
            titleLocalizationKey: "achievement.wordCollector.title",
            detailLocalizationKey: "achievement.wordCollector.detail",
            iconSystemName: "text.book.closed.fill",
            palette: [
                Color(red: 0.83, green: 0.54, blue: 0.92),
                Color(red: 0.58, green: 0.30, blue: 0.81)
            ],
            accentColor: DesignColor.aquaGlow,
            metric: .vocabularyEntries,
            targetValue: 15,
            progressFormatKey: "achievements.progress.words"
        ),
        Achievement(
            id: "quiet-power",
            titleLocalizationKey: "achievement.quietPower.title",
            detailLocalizationKey: "achievement.quietPower.detail",
            iconSystemName: "leaf.fill",
            palette: [
                Color(red: 0.57, green: 0.78, blue: 0.58),
                Color(red: 0.26, green: 0.51, blue: 0.35)
            ],
            accentColor: DesignColor.aquaGlow,
            metric: .totalRecordingMinutes,
            targetValue: 60,
            progressFormatKey: "achievements.progress.minutes"
        ),
        Achievement(
            id: "bookworm-bronze",
            titleLocalizationKey: "achievement.bookwormBronze.title",
            detailLocalizationKey: "achievement.bookwormBronze.detail",
            iconSystemName: "book.fill",
            palette: [
                Color(red: 0.78, green: 0.60, blue: 0.39),
                Color(red: 0.57, green: 0.42, blue: 0.26)
            ],
            accentColor: Color(red: 0.91, green: 0.75, blue: 0.47),
            metric: .completedBooks,
            targetValue: 1,
            progressFormatKey: "achievements.progress.books"
        ),
        Achievement(
            id: "bookworm-silver",
            titleLocalizationKey: "achievement.bookwormSilver.title",
            detailLocalizationKey: "achievement.bookwormSilver.detail",
            iconSystemName: "books.vertical.fill",
            palette: [
                Color(red: 0.78, green: 0.82, blue: 0.88),
                Color(red: 0.52, green: 0.57, blue: 0.65)
            ],
            accentColor: Color(red: 0.82, green: 0.86, blue: 0.93),
            metric: .completedBooks,
            targetValue: 3,
            progressFormatKey: "achievements.progress.books"
        ),
        Achievement(
            id: "bookworm-gold",
            titleLocalizationKey: "achievement.bookwormGold.title",
            detailLocalizationKey: "achievement.bookwormGold.detail",
            iconSystemName: "star.circle.fill",
            palette: [
                Color(red: 0.98, green: 0.83, blue: 0.32),
                Color(red: 0.90, green: 0.64, blue: 0.12)
            ],
            accentColor: DesignColor.amberGlow,
            metric: .completedBooks,
            targetValue: 5,
            progressFormatKey: "achievements.progress.books"
        ),
        Achievement(
            id: "gentle-master",
            titleLocalizationKey: "achievement.gentleMaster.title",
            detailLocalizationKey: "achievement.gentleMaster.detail",
            iconSystemName: "hands.sparkles.fill",
            palette: [
                Color(red: 0.73, green: 0.80, blue: 0.93),
                Color(red: 0.37, green: 0.53, blue: 0.88)
            ],
            accentColor: DesignColor.aquaGlow,
            metric: .totalStars,
            targetValue: 200,
            progressFormatKey: "achievements.progress.stars"
        ),
        Achievement(
            id: "explorer",
            titleLocalizationKey: "achievement.explorer.title",
            detailLocalizationKey: "achievement.explorer.detail",
            iconSystemName: "map.fill",
            palette: [
                Color(red: 0.93, green: 0.76, blue: 0.61),
                Color(red: 0.66, green: 0.46, blue: 0.27)
            ],
            accentColor: DesignColor.amberGlow,
            metric: .startedBooks,
            targetValue: 3,
            progressFormatKey: "achievements.progress.books"
        ),
        Achievement(
            id: "focus-flame",
            titleLocalizationKey: "achievement.focusFlame.title",
            detailLocalizationKey: "achievement.focusFlame.detail",
            iconSystemName: "flame.fill",
            palette: [
                Color(red: 0.97, green: 0.55, blue: 0.33),
                Color(red: 0.75, green: 0.24, blue: 0.12)
            ],
            accentColor: DesignColor.amberGlow,
            metric: .longestRecordingMinutes,
            targetValue: 10,
            progressFormatKey: "achievements.progress.minutes"
        )
    ]
}
