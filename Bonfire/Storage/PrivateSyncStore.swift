import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

protocol SyncOutboxProcessor: Sendable {
    func process(_ envelope: SyncOperationEnvelope) async throws
}

#if canImport(SwiftData)
actor PrivateSyncCoordinator {
    static let shared = PrivateSyncCoordinator()

    private let container: ModelContainer
    private var isOnline = false
    private var flushTask: Task<Void, Never>?
    private let batchSize = 10
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var outboxProcessor: SyncOutboxProcessor?

    init(container: ModelContainer? = nil) {
        if let container {
            self.container = container
        } else {
            let schema = Schema([
                UserProfileEntity.self,
                ReadingSessionEntity.self,
                WordProgressEntity.self,
                AchievementEntity.self,
                BookProgressEntity.self,
                SyncOutboxItem.self
            ])
            let configuration = ModelConfiguration(
                "PrivateSync",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            do {
                self.container = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    func register(processor: SyncOutboxProcessor?) {
        outboxProcessor = processor
        if isOnline, processor != nil {
            scheduleFlush()
        }
    }

    func updateConnectivity(isOnline: Bool) {
        guard self.isOnline != isOnline else { return }
        self.isOnline = isOnline
        if isOnline {
            scheduleFlush()
        } else {
            flushTask?.cancel()
            flushTask = nil
        }
    }

    func persistReadingSession(
        _ session: ReadingSessionSnapshot,
        bookProgress: BookProgressSnapshot
    ) async {
        await saveSnapshots(
            session: session,
            bookProgress: bookProgress,
            queueForSync: true
        )
    }

    func mergeRemote(bookProgress snapshot: BookProgressSnapshot) async {
        await saveSnapshots(session: nil, bookProgress: snapshot, queueForSync: false)
    }

    func mergeRemote(wordProgress snapshot: WordProgressSnapshot) async {
        await saveWordProgress(snapshot, queueForSync: false)
    }

    func upsertWordProgress(_ snapshot: WordProgressSnapshot) async {
        await saveWordProgress(snapshot, queueForSync: true)
    }

    func upsertUserProfile(_ snapshot: UserProfileSnapshot) async {
        await saveUserProfile(snapshot, queueForSync: true)
    }

    func mergeRemote(userProfile snapshot: UserProfileSnapshot) async {
        await saveUserProfile(snapshot, queueForSync: false)
    }

    func recordAchievement(_ snapshot: AchievementSnapshot) async {
        await saveAchievement(snapshot, queueForSync: true)
    }

    func mergeRemote(achievement snapshot: AchievementSnapshot) async {
        await saveAchievement(snapshot, queueForSync: false)
    }

    private func saveSnapshots(
        session: ReadingSessionSnapshot?,
        bookProgress: BookProgressSnapshot?,
        queueForSync: Bool
    ) async {
        do {
            let context = ModelContext(container)
            if let bookProgress {
                try upsertBookProgress(bookProgress, queueForSync: queueForSync, in: context)
            }
            if let session {
                try upsertReadingSession(session, queueForSync: queueForSync, in: context)
            }
            if context.hasChanges {
                try context.save()
            }
            if queueForSync, isOnline {
                scheduleFlush()
            }
        } catch {
            print("PrivateSyncCoordinator saveSnapshots error: \(error)")
        }
    }

    private func saveWordProgress(_ snapshot: WordProgressSnapshot, queueForSync: Bool) async {
        do {
            let context = ModelContext(container)
            try upsertWordProgress(snapshot, queueForSync: queueForSync, in: context)
            if context.hasChanges {
                try context.save()
            }
            if queueForSync, isOnline {
                scheduleFlush()
            }
        } catch {
            print("PrivateSyncCoordinator saveWordProgress error: \(error)")
        }
    }

    private func saveUserProfile(_ snapshot: UserProfileSnapshot, queueForSync: Bool) async {
        do {
            let context = ModelContext(container)
            try upsertUserProfile(snapshot, queueForSync: queueForSync, in: context)
            if context.hasChanges {
                try context.save()
            }
            if queueForSync, isOnline {
                scheduleFlush()
            }
        } catch {
            print("PrivateSyncCoordinator saveUserProfile error: \(error)")
        }
    }

    private func saveAchievement(_ snapshot: AchievementSnapshot, queueForSync: Bool) async {
        do {
            let context = ModelContext(container)
            try upsertAchievement(snapshot, queueForSync: queueForSync, in: context)
            if context.hasChanges {
                try context.save()
            }
            if queueForSync, isOnline {
                scheduleFlush()
            }
        } catch {
            print("PrivateSyncCoordinator saveAchievement error: \(error)")
        }
    }

    private func upsertBookProgress(
        _ snapshot: BookProgressSnapshot,
        queueForSync: Bool,
        in context: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<BookProgressEntity>(
            predicate: #Predicate { $0.recordName == snapshot.recordName }
        )
        let existing = try context.fetch(descriptor).first
        let entity: BookProgressEntity

        if let existing {
            var visited = existing.visitedPageIndexSet
            visited.formUnion(snapshot.visitedPageIndices)
            existing.visitedPageIndexSet = visited

            if snapshot.modifiedAt >= existing.modifiedAt {
                existing.lastPageIndex = snapshot.lastPageIndex
                existing.percentComplete = snapshot.percentComplete
                existing.lastOpenedAt = snapshot.lastOpenedAt
                existing.completedAt = snapshot.completedAt
                existing.modifiedAt = snapshot.modifiedAt
            }
            entity = existing
        } else {
            entity = BookProgressEntity(
                recordName: snapshot.recordName,
                bookID: snapshot.bookID,
                lastPageIndex: snapshot.lastPageIndex,
                percentComplete: snapshot.percentComplete,
                lastOpenedAt: snapshot.lastOpenedAt,
                completedAt: snapshot.completedAt,
                visitedPageIndices: Array(snapshot.visitedPageIndices).sorted(),
                modifiedAt: snapshot.modifiedAt
            )
            context.insert(entity)
        }

        if queueForSync {
            let envelope = try SyncOperationEnvelope(
                recordType: .bookProgress,
                recordName: snapshot.recordName,
                action: .upsert,
                payload: snapshot,
                timestamp: snapshot.modifiedAt,
                encoder: encoder
            )
            context.insert(SyncOutboxItem(envelope: envelope, encoder: encoder))
        }
    }

    private func upsertReadingSession(
        _ snapshot: ReadingSessionSnapshot,
        queueForSync: Bool,
        in context: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<ReadingSessionEntity>(
            predicate: #Predicate { $0.recordName == snapshot.recordName }
        )
        if let existing = try context.fetch(descriptor).first {
            if snapshot.modifiedAt >= existing.modifiedAt {
                existing.startedAt = snapshot.startedAt
                existing.endedAt = snapshot.endedAt
                existing.durationSeconds = snapshot.durationSeconds
                existing.wordsRead = snapshot.wordsRead
                existing.startPageIndex = snapshot.startPageIndex
                existing.endPageIndex = snapshot.endPageIndex
                existing.completedPageIndices = Array(snapshot.completedPageIndices).sorted()
                existing.notes = snapshot.notes
                existing.modifiedAt = snapshot.modifiedAt
            }
        } else {
            let entity = ReadingSessionEntity(
                recordName: snapshot.recordName,
                bookID: snapshot.bookID,
                startedAt: snapshot.startedAt,
                endedAt: snapshot.endedAt,
                durationSeconds: snapshot.durationSeconds,
                wordsRead: snapshot.wordsRead,
                startPageIndex: snapshot.startPageIndex,
                endPageIndex: snapshot.endPageIndex,
                completedPageIndices: Array(snapshot.completedPageIndices).sorted(),
                notes: snapshot.notes,
                modifiedAt: snapshot.modifiedAt,
                createdOfflineAt: Date()
            )
            context.insert(entity)
        }

        if queueForSync {
            let envelope = try SyncOperationEnvelope(
                recordType: .readingSession,
                recordName: snapshot.recordName,
                action: .upsert,
                payload: snapshot,
                timestamp: snapshot.modifiedAt,
                encoder: encoder
            )
            context.insert(SyncOutboxItem(envelope: envelope, encoder: encoder))
        }
    }

    private func upsertWordProgress(
        _ snapshot: WordProgressSnapshot,
        queueForSync: Bool,
        in context: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<WordProgressEntity>(
            predicate: #Predicate { $0.recordName == snapshot.recordName }
        )
        let existing = try context.fetch(descriptor).first
        if let existing {
            if snapshot.modifiedAt >= existing.modifiedAt {
                existing.lemma = snapshot.lemma
                existing.bookID = snapshot.bookID
                existing.proficiency = snapshot.proficiency
                existing.correctCount = snapshot.correctCount
                existing.incorrectCount = snapshot.incorrectCount
                existing.lastReviewedAt = snapshot.lastReviewedAt
                existing.modifiedAt = snapshot.modifiedAt
            }
        } else {
            let entity = WordProgressEntity(
                recordName: snapshot.recordName,
                lemma: snapshot.lemma,
                bookID: snapshot.bookID,
                proficiency: snapshot.proficiency,
                correctCount: snapshot.correctCount,
                incorrectCount: snapshot.incorrectCount,
                lastReviewedAt: snapshot.lastReviewedAt,
                modifiedAt: snapshot.modifiedAt
            )
            context.insert(entity)
        }

        if queueForSync {
            let envelope = try SyncOperationEnvelope(
                recordType: .wordProgress,
                recordName: snapshot.recordName,
                action: .upsert,
                payload: snapshot,
                timestamp: snapshot.modifiedAt,
                encoder: encoder
            )
            context.insert(SyncOutboxItem(envelope: envelope, encoder: encoder))
        }
    }

    private func upsertUserProfile(
        _ snapshot: UserProfileSnapshot,
        queueForSync: Bool,
        in context: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<UserProfileEntity>(
            predicate: #Predicate { $0.recordName == snapshot.recordName }
        )
        let existing = try context.fetch(descriptor).first
        if let existing {
            if snapshot.modifiedAt >= existing.modifiedAt {
                existing.displayName = snapshot.displayName
                existing.preferredLocale = snapshot.preferredLocale
                existing.readingStreak = snapshot.readingStreak
                existing.lastSessionAt = snapshot.lastSessionAt
                existing.modifiedAt = snapshot.modifiedAt
            }
        } else {
            let entity = UserProfileEntity(
                recordName: snapshot.recordName,
                displayName: snapshot.displayName,
                preferredLocale: snapshot.preferredLocale,
                readingStreak: snapshot.readingStreak,
                lastSessionAt: snapshot.lastSessionAt,
                modifiedAt: snapshot.modifiedAt
            )
            context.insert(entity)
        }

        if queueForSync {
            let envelope = try SyncOperationEnvelope(
                recordType: .userProfile,
                recordName: snapshot.recordName,
                action: .upsert,
                payload: snapshot,
                timestamp: snapshot.modifiedAt,
                encoder: encoder
            )
            context.insert(SyncOutboxItem(envelope: envelope, encoder: encoder))
        }
    }

    private func upsertAchievement(
        _ snapshot: AchievementSnapshot,
        queueForSync: Bool,
        in context: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<AchievementEntity>(
            predicate: #Predicate { $0.recordName == snapshot.recordName }
        )
        let existing = try context.fetch(descriptor).first
        if let existing {
            if snapshot.modifiedAt >= existing.modifiedAt {
                existing.code = snapshot.code
                existing.earnedAt = snapshot.earnedAt
                existing.progressValue = snapshot.progressValue
                existing.detail = snapshot.detail
                existing.modifiedAt = snapshot.modifiedAt
            }
        } else {
            let entity = AchievementEntity(
                recordName: snapshot.recordName,
                code: snapshot.code,
                earnedAt: snapshot.earnedAt,
                progressValue: snapshot.progressValue,
                detail: snapshot.detail,
                modifiedAt: snapshot.modifiedAt
            )
            context.insert(entity)
        }

        if queueForSync {
            let envelope = try SyncOperationEnvelope(
                recordType: .achievement,
                recordName: snapshot.recordName,
                action: .upsert,
                payload: snapshot,
                timestamp: snapshot.modifiedAt,
                encoder: encoder
            )
            context.insert(SyncOutboxItem(envelope: envelope, encoder: encoder))
        }
    }

    private func scheduleFlush() {
        guard flushTask == nil || flushTask?.isCancelled == true else { return }
        guard outboxProcessor != nil else { return }

        flushTask = Task(priority: .background) {
            await self.executeFlush()
        }
    }

    private func executeFlush() async {
        defer { flushTask = nil }
        guard let processor = outboxProcessor else { return }

        do {
            var shouldContinue = true
            while shouldContinue {
                if Task.isCancelled || !isOnline { return }
                let context = ModelContext(container)
                let descriptor = FetchDescriptor<SyncOutboxItem>(
                    sortBy: [SortDescriptor(\.queuedAt, order: .forward)],
                    fetchLimit: batchSize
                )
                let items = try context.fetch(descriptor)
                guard !items.isEmpty else { return }

                for item in items {
                    if Task.isCancelled || !isOnline { return }
                    guard let envelope = item.makeEnvelope(decoder: decoder) else {
                        context.delete(item)
                        continue
                    }

                    do {
                        try await processor.process(envelope)
                        context.delete(item)
                    } catch {
                        item.attemptCount += 1
                        item.lastAttemptAt = Date()
                        item.lastErrorMessage = error.localizedDescription
                    }
                }

                if context.hasChanges {
                    try context.save()
                }

                shouldContinue = items.count == batchSize
            }
        } catch {
            print("PrivateSyncCoordinator executeFlush error: \(error)")
        }
    }
}
#else
actor PrivateSyncCoordinator {
    static let shared = PrivateSyncCoordinator()

    private var isOnline = false
    private var outboxProcessor: SyncOutboxProcessor?
    private var pendingEnvelopes: [SyncOperationEnvelope] = []
    private let encoder = JSONEncoder()

    func register(processor: SyncOutboxProcessor?) {
        outboxProcessor = processor
        Task { await flushPendingIfNeeded() }
    }

    func updateConnectivity(isOnline: Bool) {
        guard self.isOnline != isOnline else { return }
        self.isOnline = isOnline
        if isOnline {
            Task { await flushPendingIfNeeded() }
        }
    }

    func persistReadingSession(
        _ session: ReadingSessionSnapshot,
        bookProgress: BookProgressSnapshot
    ) async {
        await queueEnvelope {
            try SyncOperationEnvelope(
                recordType: .bookProgress,
                recordName: bookProgress.recordName,
                action: .upsert,
                payload: bookProgress,
                timestamp: bookProgress.modifiedAt,
                encoder: encoder
            )
        }

        await queueEnvelope {
            try SyncOperationEnvelope(
                recordType: .readingSession,
                recordName: session.recordName,
                action: .upsert,
                payload: session,
                timestamp: session.modifiedAt,
                encoder: encoder
            )
        }
    }

    func mergeRemote(bookProgress _: BookProgressSnapshot) async {}

    func mergeRemote(wordProgress _: WordProgressSnapshot) async {}

    func upsertWordProgress(_ snapshot: WordProgressSnapshot) async {
        await queueEnvelope {
            try SyncOperationEnvelope(
                recordType: .wordProgress,
                recordName: snapshot.recordName,
                action: .upsert,
                payload: snapshot,
                timestamp: snapshot.modifiedAt,
                encoder: encoder
            )
        }
    }

    func upsertUserProfile(_ snapshot: UserProfileSnapshot) async {
        await queueEnvelope {
            try SyncOperationEnvelope(
                recordType: .userProfile,
                recordName: snapshot.recordName,
                action: .upsert,
                payload: snapshot,
                timestamp: snapshot.modifiedAt,
                encoder: encoder
            )
        }
    }

    func mergeRemote(userProfile _: UserProfileSnapshot) async {}

    func recordAchievement(_ snapshot: AchievementSnapshot) async {
        await queueEnvelope {
            try SyncOperationEnvelope(
                recordType: .achievement,
                recordName: snapshot.recordName,
                action: .upsert,
                payload: snapshot,
                timestamp: snapshot.modifiedAt,
                encoder: encoder
            )
        }
    }

    func mergeRemote(achievement _: AchievementSnapshot) async {}

    private func queueEnvelope(_ builder: () throws -> SyncOperationEnvelope) async {
        do {
            let envelope = try builder()
            if isOnline, let processor = outboxProcessor {
                do {
                    try await processor.process(envelope)
                } catch {
                    pendingEnvelopes.append(envelope)
                    print("PrivateSyncCoordinator process error: \(error)")
                }
            } else {
                pendingEnvelopes.append(envelope)
            }
        } catch {
            print("PrivateSyncCoordinator encode error: \(error)")
        }
    }

    private func flushPendingIfNeeded() async {
        guard isOnline, let processor = outboxProcessor else { return }
        var remaining: [SyncOperationEnvelope] = []

        for envelope in pendingEnvelopes {
            do {
                try await processor.process(envelope)
            } catch {
                remaining.append(envelope)
                print("PrivateSyncCoordinator flush error: \(error)")
            }
        }

        pendingEnvelopes = remaining
    }
}
#endif
