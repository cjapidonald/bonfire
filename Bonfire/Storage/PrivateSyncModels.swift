import Foundation
import SwiftData

enum PrivateRecordType: String, Codable, Sendable {
    case userProfile
    case readingSession
    case wordProgress
    case achievement
    case bookProgress
}

enum SyncAction: String, Codable, Sendable {
    case upsert
    case delete
}

struct SyncOperationEnvelope: Codable, Sendable, Identifiable {
    let id: UUID
    let recordType: PrivateRecordType
    let recordName: String
    let action: SyncAction
    let payload: Data?
    let timestamp: Date
    let metadata: [String: String]?

    init(
        id: UUID = UUID(),
        recordType: PrivateRecordType,
        recordName: String,
        action: SyncAction,
        payload: Data?,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.recordType = recordType
        self.recordName = recordName
        self.action = action
        self.payload = payload
        self.timestamp = timestamp
        self.metadata = metadata
    }

    init<T: Encodable & Sendable>(
        id: UUID = UUID(),
        recordType: PrivateRecordType,
        recordName: String,
        action: SyncAction,
        payload: T?,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil,
        encoder: JSONEncoder = JSONEncoder()
    ) throws {
        let encodedPayload: Data?
        if let payload {
            encodedPayload = try encoder.encode(payload)
        } else {
            encodedPayload = nil
        }
        self.init(
            id: id,
            recordType: recordType,
            recordName: recordName,
            action: action,
            payload: encodedPayload,
            timestamp: timestamp,
            metadata: metadata
        )
    }

    func decodePayload<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let payload else { return nil }
        return try? decoder.decode(type, from: payload)
    }
}

struct UserProfileSnapshot: Codable, Sendable {
    let recordName: String
    var displayName: String?
    var preferredLocale: String
    var readingStreak: Int
    var lastSessionAt: Date?
    var modifiedAt: Date
}

struct ReadingSessionSnapshot: Codable, Sendable {
    let recordName: String
    let bookID: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: TimeInterval
    var wordsRead: Int?
    var startPageIndex: Int?
    var endPageIndex: Int?
    var completedPageIndices: Set<Int>
    var notes: String?
    var modifiedAt: Date
}

struct WordProgressSnapshot: Codable, Sendable {
    let recordName: String
    let lemma: String
    var bookID: UUID?
    var proficiency: Double
    var correctCount: Int
    var incorrectCount: Int
    var lastReviewedAt: Date?
    var modifiedAt: Date
}

struct AchievementSnapshot: Codable, Sendable {
    let recordName: String
    var code: String
    var earnedAt: Date
    var progressValue: Double?
    var detail: String?
    var modifiedAt: Date
}

struct BookProgressSnapshot: Codable, Sendable {
    let recordName: String
    let bookID: UUID
    var lastPageIndex: Int
    var percentComplete: Double
    var lastOpenedAt: Date?
    var completedAt: Date?
    var visitedPageIndices: Set<Int>
    var modifiedAt: Date
}

@Model final class UserProfileEntity {
    @Attribute(.unique) var recordName: String
    var displayName: String?
    var preferredLocale: String
    var readingStreak: Int
    var lastSessionAt: Date?
    var modifiedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ReadingSessionEntity.user) var sessions: [ReadingSessionEntity]
    @Relationship(deleteRule: .cascade, inverse: \WordProgressEntity.user) var wordProgress: [WordProgressEntity]
    @Relationship(deleteRule: .cascade, inverse: \AchievementEntity.user) var achievements: [AchievementEntity]
    @Relationship(deleteRule: .cascade, inverse: \BookProgressEntity.user) var bookProgress: [BookProgressEntity]

    init(
        recordName: String,
        displayName: String?,
        preferredLocale: String,
        readingStreak: Int,
        lastSessionAt: Date?,
        modifiedAt: Date
    ) {
        self.recordName = recordName
        self.displayName = displayName
        self.preferredLocale = preferredLocale
        self.readingStreak = readingStreak
        self.lastSessionAt = lastSessionAt
        self.modifiedAt = modifiedAt
        self.sessions = []
        self.wordProgress = []
        self.achievements = []
        self.bookProgress = []
    }
}

@Model final class ReadingSessionEntity {
    @Attribute(.unique) var recordName: String
    var bookID: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: TimeInterval
    var wordsRead: Int?
    var startPageIndex: Int?
    var endPageIndex: Int?
    var completedPageIndices: [Int]
    var notes: String?
    var modifiedAt: Date
    var createdOfflineAt: Date

    @Relationship(deleteRule: .nullify, inverse: \UserProfileEntity.sessions) var user: UserProfileEntity?

    init(
        recordName: String,
        bookID: UUID,
        startedAt: Date,
        endedAt: Date?,
        durationSeconds: TimeInterval,
        wordsRead: Int?,
        startPageIndex: Int?,
        endPageIndex: Int?,
        completedPageIndices: [Int],
        notes: String?,
        modifiedAt: Date,
        createdOfflineAt: Date
    ) {
        self.recordName = recordName
        self.bookID = bookID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.wordsRead = wordsRead
        self.startPageIndex = startPageIndex
        self.endPageIndex = endPageIndex
        self.completedPageIndices = completedPageIndices
        self.notes = notes
        self.modifiedAt = modifiedAt
        self.createdOfflineAt = createdOfflineAt
    }
}

@Model final class WordProgressEntity {
    @Attribute(.unique) var recordName: String
    var lemma: String
    var bookID: UUID?
    var proficiency: Double
    var correctCount: Int
    var incorrectCount: Int
    var lastReviewedAt: Date?
    var modifiedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \UserProfileEntity.wordProgress) var user: UserProfileEntity?

    init(
        recordName: String,
        lemma: String,
        bookID: UUID?,
        proficiency: Double,
        correctCount: Int,
        incorrectCount: Int,
        lastReviewedAt: Date?,
        modifiedAt: Date
    ) {
        self.recordName = recordName
        self.lemma = lemma
        self.bookID = bookID
        self.proficiency = proficiency
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.lastReviewedAt = lastReviewedAt
        self.modifiedAt = modifiedAt
    }
}

@Model final class AchievementEntity {
    @Attribute(.unique) var recordName: String
    var code: String
    var earnedAt: Date
    var progressValue: Double?
    var detail: String?
    var modifiedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \UserProfileEntity.achievements) var user: UserProfileEntity?

    init(
        recordName: String,
        code: String,
        earnedAt: Date,
        progressValue: Double?,
        detail: String?,
        modifiedAt: Date
    ) {
        self.recordName = recordName
        self.code = code
        self.earnedAt = earnedAt
        self.progressValue = progressValue
        self.detail = detail
        self.modifiedAt = modifiedAt
    }
}

@Model final class BookProgressEntity {
    @Attribute(.unique) var recordName: String
    var bookID: UUID
    var lastPageIndex: Int
    var percentComplete: Double
    var lastOpenedAt: Date?
    var completedAt: Date?
    var visitedPageIndices: [Int]
    var modifiedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \UserProfileEntity.bookProgress) var user: UserProfileEntity?

    init(
        recordName: String,
        bookID: UUID,
        lastPageIndex: Int,
        percentComplete: Double,
        lastOpenedAt: Date?,
        completedAt: Date?,
        visitedPageIndices: [Int],
        modifiedAt: Date
    ) {
        self.recordName = recordName
        self.bookID = bookID
        self.lastPageIndex = lastPageIndex
        self.percentComplete = percentComplete
        self.lastOpenedAt = lastOpenedAt
        self.completedAt = completedAt
        self.visitedPageIndices = visitedPageIndices
        self.modifiedAt = modifiedAt
    }

    var visitedPageIndexSet: Set<Int> {
        get { Set(visitedPageIndices) }
        set { visitedPageIndices = Array(newValue).sorted() }
    }
}

@Model final class SyncOutboxItem {
    @Attribute(.unique) var identifier: UUID
    var recordTypeRaw: String
    var recordName: String
    var actionRaw: String
    var payload: Data?
    var metadata: Data?
    var queuedAt: Date
    var attemptCount: Int
    var lastErrorMessage: String?
    var lastAttemptAt: Date?

    init(envelope: SyncOperationEnvelope, encoder: JSONEncoder = JSONEncoder()) {
        self.identifier = envelope.id
        self.recordTypeRaw = envelope.recordType.rawValue
        self.recordName = envelope.recordName
        self.actionRaw = envelope.action.rawValue
        self.payload = envelope.payload
        if let metadata = envelope.metadata {
            self.metadata = try? encoder.encode(metadata)
        } else {
            self.metadata = nil
        }
        self.queuedAt = envelope.timestamp
        self.attemptCount = 0
    }

    func makeEnvelope(decoder: JSONDecoder = JSONDecoder()) -> SyncOperationEnvelope? {
        guard let recordType = PrivateRecordType(rawValue: recordTypeRaw),
              let action = SyncAction(rawValue: actionRaw) else {
            return nil
        }

        let decodedMetadata: [String: String]?
        if let metadata, let metadataDictionary = try? decoder.decode([String: String].self, from: metadata) {
            decodedMetadata = metadataDictionary
        } else {
            decodedMetadata = nil
        }

        return SyncOperationEnvelope(
            id: identifier,
            recordType: recordType,
            recordName: recordName,
            action: action,
            payload: payload,
            timestamp: queuedAt,
            metadata: decodedMetadata
        )
    }
}
