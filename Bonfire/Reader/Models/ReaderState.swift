import Combine
import Foundation

protocol ReaderLevelStoring {
    func level(for bookID: Book.ID) -> Level?
    func save(level: Level, for bookID: Book.ID)
}

/// Stores per-book reading preferences such as the selected difficulty level.
final class ReaderLevelStore: ReaderLevelStoring {
    static let shared = ReaderLevelStore()

    private let storageKey = "reader.level.preferences"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func level(for bookID: Book.ID) -> Level? {
        guard
            let rawLevels = userDefaults.dictionary(forKey: storageKey) as? [String: String],
            let rawValue = rawLevels[bookID.uuidString],
            let level = Level(rawValue: rawValue)
        else {
            return nil
        }

        return level
    }

    func save(level: Level, for bookID: Book.ID) {
        var rawLevels = userDefaults.dictionary(forKey: storageKey) as? [String: String] ?? [:]
        rawLevels[bookID.uuidString] = level.rawValue
        userDefaults.set(rawLevels, forKey: storageKey)
    }
}

/// Represents the reader's state for a specific book, including difficulty level.
final class ReaderState: ObservableObject {
    @Published var level: Level {
        didSet {
            guard oldValue != level else { return }
            levelStore.save(level: level, for: bookID)
            AnalyticsLogger.shared.log(
                event: "level_changed",
                metadata: [
                    "book_id": bookID.uuidString,
                    "level": level.rawValue
                ]
            )
        }
    }

    private let bookID: Book.ID
    private let levelStore: ReaderLevelStoring

    init(book: Book, levelStore: ReaderLevelStoring = ReaderLevelStore.shared) {
        self.bookID = book.id
        self.levelStore = levelStore
        self.level = levelStore.level(for: book.id) ?? book.level
    }
}
