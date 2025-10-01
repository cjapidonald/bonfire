import Combine
import Foundation

struct SessionReward {
    let starsAwarded: Int
    let newlyVisitedPageIndices: [Int]
    let updatedProgress: BookProgress
}

struct DailyReadingSummary: Codable, Hashable {
    let date: Date
    private(set) var totalSeconds: TimeInterval
    private(set) var starsEarned: Int

    init(date: Date, totalSeconds: TimeInterval = 0, starsEarned: Int = 0) {
        self.date = date
        self.totalSeconds = totalSeconds
        self.starsEarned = starsEarned
    }

    mutating func addSession(duration: TimeInterval, stars: Int) {
        totalSeconds += duration
        starsEarned += stars
    }

    var totalMinutes: Int {
        Int(totalSeconds / 60)
    }

    var hasActivity: Bool {
        totalSeconds >= 60 || starsEarned > 0
    }
}

final class ReaderProgressStore: ObservableObject {
    static let shared = ReaderProgressStore()

    @Published private(set) var progressByBook: [Book.ID: BookProgress]
    @Published private(set) var totalStars: Int
    @Published private(set) var dailySummaries: [Date: DailyReadingSummary]

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let progressKey = "reader.progress.records"
    private let starsKey = "reader.progress.stars"
    private let dailySummariesKey = "reader.progress.dailySummaries"
    private let baselineWordsPerMinute: Double = 160
    private var calendar = Calendar.current
    private let privateSync = PrivateSyncCoordinator.shared

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        calendar.timeZone = TimeZone.current

        if let data = userDefaults.data(forKey: progressKey),
           let decoded = try? decoder.decode([String: BookProgress].self, from: data) {
            progressByBook = decoded.reduce(into: [:]) { partialResult, entry in
                guard let bookID = UUID(uuidString: entry.key) else { return }
                partialResult[bookID] = entry.value
            }
        } else {
            progressByBook = [:]
        }

        totalStars = userDefaults.integer(forKey: starsKey)

        if let data = userDefaults.data(forKey: dailySummariesKey),
           let decoded = try? decoder.decode([DailyReadingSummary].self, from: data) {
            dailySummaries = decoded.reduce(into: [:]) { partialResult, summary in
                partialResult[summary.date] = summary
            }
        } else {
            dailySummaries = [:]
        }
    }

    func progress(for book: Book) -> BookProgress {
        progressByBook[book.id] ?? BookProgress(bookID: book.id, currentPageIndex: book.pages.first?.index ?? 0)
    }

    @discardableResult
    func recordSession(
        for book: Book,
        level: Level,
        totalWordsCounted: Int,
        uniqueWordCounts: [Int: Int],
        recording: ReaderRecordingSession,
        qualityFactor: Double,
        lastViewedPageIndex: Int
    ) -> SessionReward {
        let multiplier = starMultiplier(for: level)
        let rawStars = Double(totalWordsCounted) * multiplier * qualityFactor
        let starsAwarded = max(0, Int(rawStars.rounded()))
        if starsAwarded > 0 {
            totalStars += starsAwarded
            persistStarTotal()
        }

        var progress = progressByBook[book.id] ?? BookProgress(bookID: book.id, currentPageIndex: book.pages.first?.index ?? 0)
        let visitedBefore = progress.visitedPageIndices
        let sessionVisited = visitedPages(
            for: book,
            level: level,
            uniqueWordCounts: uniqueWordCounts,
            recordingDuration: recording.duration,
            totalWordsCounted: totalWordsCounted
        )

        progress.visitedPageIndices.formUnion(sessionVisited)
        let furthestVisited = progress.visitedPageIndices.max() ?? 0
        progress.currentPageIndex = max(progress.currentPageIndex, max(lastViewedPageIndex, furthestVisited))
        progress.lastReadAt = recording.createdAt
        progress.isCompleted = progress.visitedPageIndices.count >= book.pages.count

        progressByBook[book.id] = progress
        persistProgress()

        let newlyVisited = Array(sessionVisited.subtracting(visitedBefore)).sorted()

        updateDailySummary(for: recording.createdAt, duration: recording.duration, stars: starsAwarded)

        let reward = SessionReward(
            starsAwarded: starsAwarded,
            newlyVisitedPageIndices: newlyVisited,
            updatedProgress: progress
        )

        schedulePrivateSync(
            for: book,
            sessionVisited: sessionVisited,
            totalWordsCounted: totalWordsCounted,
            recording: recording,
            updatedProgress: progress
        )

        return reward
    }

    private func schedulePrivateSync(
        for book: Book,
        sessionVisited: Set<Int>,
        totalWordsCounted: Int,
        recording: ReaderRecordingSession,
        updatedProgress: BookProgress
    ) {
        let startIndex = sessionVisited.min()
        let endIndex = sessionVisited.max()
        let now = Date()

        let sessionSnapshot = ReadingSessionSnapshot(
            recordName: UUID().uuidString,
            bookID: book.id,
            startedAt: recording.createdAt.addingTimeInterval(-recording.duration),
            endedAt: recording.createdAt,
            durationSeconds: recording.duration,
            wordsRead: totalWordsCounted,
            startPageIndex: startIndex,
            endPageIndex: endIndex,
            completedPageIndices: sessionVisited,
            modifiedAt: now
        )

        let percentComplete: Double
        if book.pages.isEmpty {
            percentComplete = 0
        } else {
            percentComplete = Double(updatedProgress.visitedPageIndices.count) / Double(book.pages.count)
        }

        let bookSnapshot = BookProgressSnapshot(
            recordName: book.id.uuidString,
            bookID: book.id,
            lastPageIndex: updatedProgress.currentPageIndex,
            percentComplete: percentComplete,
            lastOpenedAt: updatedProgress.lastReadAt,
            completedAt: updatedProgress.isCompleted ? updatedProgress.lastReadAt : nil,
            visitedPageIndices: updatedProgress.visitedPageIndices,
            modifiedAt: now
        )

        Task(priority: .utility) { [sessionSnapshot, bookSnapshot] in
            await privateSync.persistReadingSession(
                sessionSnapshot,
                bookProgress: bookSnapshot
            )
        }
    }

    var todaySummary: DailyReadingSummary {
        let today = normalizedDate(for: Date())
        return dailySummaries[today] ?? DailyReadingSummary(date: today)
    }

    func weeklySummaries(referenceDate: Date = Date()) -> [DailyReadingSummary] {
        let today = normalizedDate(for: referenceDate)
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let normalized = normalizedDate(for: date)
            return dailySummaries[normalized] ?? DailyReadingSummary(date: normalized)
        }
        .sorted(by: { $0.date < $1.date })
    }

    var currentStreakCount: Int {
        var streak = 0
        var cursor = normalizedDate(for: Date())

        while let summary = dailySummaries[cursor], summary.hasActivity {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = normalizedDate(for: previous)
        }

        return streak
    }

    var mostRecentBookProgress: BookProgress? {
        progressByBook.values
            .sorted(by: { ($0.lastReadAt ?? .distantPast) > ($1.lastReadAt ?? .distantPast) })
            .first
    }

    private func visitedPages(
        for book: Book,
        level: Level,
        uniqueWordCounts: [Int: Int],
        recordingDuration: TimeInterval,
        totalWordsCounted: Int
    ) -> Set<Int> {
        guard totalWordsCounted > 0 else { return [] }

        let pagesByIndex = Dictionary(uniqueKeysWithValues: book.pages.map { ($0.index, $0) })
        var visited: Set<Int> = []

        for (pageIndex, countedWords) in uniqueWordCounts {
            guard let page = pagesByIndex[pageIndex] else { continue }

            let totalWordsOnPage = max(1, page.wordCount(for: level))
            let countedRatio = Double(countedWords) / Double(totalWordsOnPage)

            var audioRatio: Double = 0
            if recordingDuration > 0 {
                let share = Double(countedWords) / Double(totalWordsCounted)
                let estimatedDuration = estimatedReadDuration(forWordCount: totalWordsOnPage)
                if estimatedDuration > 0 {
                    let allocatedDuration = recordingDuration * share
                    audioRatio = min(1, allocatedDuration / estimatedDuration)
                }
            }

            if countedRatio >= 0.6 || audioRatio >= 0.6 {
                visited.insert(pageIndex)
            }
        }

        return visited
    }

    private func starMultiplier(for level: Level) -> Double {
        switch level {
        case .a1:
            return 1.0
        case .a2:
            return 1.2
        case .b1:
            return 1.6
        case .b2:
            return 2.0
        }
    }

    private func estimatedReadDuration(forWordCount wordCount: Int) -> TimeInterval {
        guard wordCount > 0 else { return 0 }
        let minutes = Double(wordCount) / baselineWordsPerMinute
        return minutes * 60
    }

    private func persistProgress() {
        let payload = progressByBook.reduce(into: [String: BookProgress]()) { partialResult, entry in
            partialResult[entry.key.uuidString] = entry.value
        }

        do {
            let data = try encoder.encode(payload)
            userDefaults.set(data, forKey: progressKey)
        } catch {
            print("Failed to persist reader progress: \(error)")
        }
    }

    private func persistStarTotal() {
        userDefaults.set(totalStars, forKey: starsKey)
    }

    private func updateDailySummary(for date: Date, duration: TimeInterval, stars: Int) {
        let normalizedDate = normalizedDate(for: date)
        var summary = dailySummaries[normalizedDate] ?? DailyReadingSummary(date: normalizedDate)
        summary.addSession(duration: duration, stars: stars)
        dailySummaries[normalizedDate] = summary
        persistDailySummaries()
    }

    private func normalizedDate(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    private func persistDailySummaries() {
        let summaries = Array(dailySummaries.values)

        do {
            let data = try encoder.encode(summaries)
            userDefaults.set(data, forKey: dailySummariesKey)
        } catch {
            print("Failed to persist daily summaries: \(error)")
        }
    }
}

#if DEBUG
extension ReaderProgressStore {
    func debugReset() {
        progressByBook = [:]
        totalStars = 0
        dailySummaries = [:]
        userDefaults.removeObject(forKey: progressKey)
        userDefaults.removeObject(forKey: starsKey)
        userDefaults.removeObject(forKey: dailySummariesKey)
    }

    func debugSeedProgress() {
        let books = ContentProvider.shared.books
        let now = Date()

        var seeded: [Book.ID: BookProgress] = [:]
        for index in 0..<max(books.count, 5) {
            let bookID: UUID
            let pageCount: Int

            if index < books.count {
                let book = books[index]
                bookID = book.id
                pageCount = max(book.pages.count, 12)
            } else {
                bookID = UUID()
                pageCount = 12
            }

            let visited = Set(0..<pageCount)
            let progress = BookProgress(
                bookID: bookID,
                currentPageIndex: pageCount - 1,
                isCompleted: true,
                lastReadAt: now.addingTimeInterval(TimeInterval(-index * 3600)),
                visitedPageIndices: visited
            )
            seeded[bookID] = progress
        }

        progressByBook = seeded
        persistProgress()
    }

    func debugBoostStarCount() {
        totalStars = max(totalStars, 250)
        persistStarTotal()
        let today = normalizedDate(for: Date())
        var summary = dailySummaries[today] ?? DailyReadingSummary(date: today)
        summary.addSession(duration: 45 * 60, stars: 75)
        dailySummaries[today] = summary
        persistDailySummaries()
    }
}
#endif
