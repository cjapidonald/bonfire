import Combine
import Foundation

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published private(set) var progress: [AchievementProgress]

    private var cancellables: Set<AnyCancellable> = []

    init(progress: [AchievementProgress]) {
        self.progress = progress
    }

    convenience init(
        recordingStore: ReaderRecordingStore = .shared,
        progressStore: ReaderProgressStore = .shared,
        vocabularyStore: VocabularyStore = .shared
    ) {
        self.init(progress: AchievementRegistry.all.map { $0.progress(for: .zero) })
        bind(
            recordingStore: recordingStore,
            progressStore: progressStore,
            vocabularyStore: vocabularyStore
        )
    }

    private func bind(
        recordingStore: ReaderRecordingStore,
        progressStore: ReaderProgressStore,
        vocabularyStore: VocabularyStore
    ) {
        Publishers.CombineLatest3(
            recordingStore.$sessionsByBook,
            progressStore.$progressByBook,
            progressStore.$totalStars
        )
        .combineLatest(vocabularyStore.$entries)
        .map { combined, entries -> [AchievementProgress] in
            let (sessionsByBook, progressByBook, totalStars) = combined
            let metrics = AchievementMetrics(
                recordingSessions: sessionsByBook.values.reduce(0) { partialResult, sessions in
                    partialResult + sessions.count
                },
                totalRecordingMinutes: sessionsByBook.values.flatMap { $0 }.reduce(0) { partialResult, session in
                    partialResult + session.duration / 60
                },
                vocabularyEntries: entries.count,
                completedBooks: progressByBook.values.filter { $0.isCompleted }.count,
                startedBooks: progressByBook.values.filter { !$0.visitedPageIndices.isEmpty }.count,
                totalStars: totalStars,
                longestRecordingMinutes: sessionsByBook.values.flatMap { $0 }
                    .map { $0.duration / 60 }
                    .max() ?? 0
            )

            return AchievementRegistry.all.map { $0.progress(for: metrics) }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] progress in
            self?.progress = progress
        }
        .store(in: &cancellables)
    }
}

extension AchievementsViewModel {
    static var preview: AchievementsViewModel {
        let mockMetrics = AchievementMetrics(
            recordingSessions: 7,
            totalRecordingMinutes: 48,
            vocabularyEntries: 9,
            completedBooks: 2,
            startedBooks: 4,
            totalStars: 120,
            longestRecordingMinutes: 8
        )
        let samples = AchievementRegistry.all.map { $0.progress(for: mockMetrics) }
        return AchievementsViewModel(progress: samples)
    }
}
