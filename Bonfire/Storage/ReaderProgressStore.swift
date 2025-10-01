import Combine
import Foundation

struct SessionReward {
    let starsAwarded: Int
    let newlyVisitedPageIndices: [Int]
    let updatedProgress: BookProgress
}

final class ReaderProgressStore: ObservableObject {
    static let shared = ReaderProgressStore()

    @Published private(set) var progressByBook: [Book.ID: BookProgress]
    @Published private(set) var totalStars: Int

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let progressKey = "reader.progress.records"
    private let starsKey = "reader.progress.stars"
    private let baselineWordsPerMinute: Double = 160

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

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

        return SessionReward(
            starsAwarded: starsAwarded,
            newlyVisitedPageIndices: newlyVisited,
            updatedProgress: progress
        )
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
}
