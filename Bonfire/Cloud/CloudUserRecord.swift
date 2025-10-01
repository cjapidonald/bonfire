import CloudKit

/// CloudKit record type names used for Private database user data.
enum CloudUserRecordType {
    static let userProfile = "UserProfile"
    static let readingSession = "ReadingSession"
    static let wordProgress = "WordProgress"
    static let achievement = "Achievement"
    static let bookProgress = "BookProgress"
}

/// Field keys for the `UserProfile` record type stored in the Private database.
enum CloudUserProfileFields {
    static let displayName = "displayName"
    static let preferredLocale = "preferredLocale"
    static let readingStreak = "readingStreak"
    static let lastSessionAt = "lastSessionAt"
}

/// Field keys for the `ReadingSession` record type.
enum CloudReadingSessionFields {
    static let user = "user"
    static let book = "book"
    static let startedAt = "startedAt"
    static let endedAt = "endedAt"
    static let durationSeconds = "durationSeconds"
    static let wordsRead = "wordsRead"
    static let startPageIndex = "startPageIndex"
    static let endPageIndex = "endPageIndex"
    static let audioAsset = "audioAsset"
    static let notes = "notes"
}

/// Field keys for the `WordProgress` record type.
enum CloudWordProgressFields {
    static let user = "user"
    static let book = "book"
    static let lemma = "lemma"
    static let proficiency = "proficiency"
    static let correctCount = "correctCount"
    static let incorrectCount = "incorrectCount"
    static let lastReviewedAt = "lastReviewedAt"
}

/// Field keys for the `Achievement` record type.
enum CloudAchievementFields {
    static let user = "user"
    static let code = "code"
    static let earnedAt = "earnedAt"
    static let progressValue = "progressValue"
    static let detail = "detail"
}

/// Field keys for the `BookProgress` record type.
enum CloudBookProgressFields {
    static let user = "user"
    static let book = "book"
    static let lastPageIndex = "lastPageIndex"
    static let percentComplete = "percentComplete"
    static let lastOpenedAt = "lastOpenedAt"
    static let completedAt = "completedAt"
}

