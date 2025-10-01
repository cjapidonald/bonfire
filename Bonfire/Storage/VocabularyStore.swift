import Combine
import Foundation

struct VocabularyEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let original: String
    let normalized: String
    let translation: String
    let partOfSpeech: WordPartOfSpeech
    let englishDefinition: String?
    let sampleSentence: String
    let bookID: UUID
    let pageIndex: Int
    let dateAdded: Date

    init(
        id: UUID = UUID(),
        original: String,
        normalized: String,
        translation: String,
        partOfSpeech: WordPartOfSpeech,
        englishDefinition: String?,
        sampleSentence: String,
        bookID: UUID,
        pageIndex: Int,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.original = original
        self.normalized = normalized
        self.translation = translation
        self.partOfSpeech = partOfSpeech
        self.englishDefinition = englishDefinition
        self.sampleSentence = sampleSentence
        self.bookID = bookID
        self.pageIndex = pageIndex
        self.dateAdded = dateAdded
    }
}

final class VocabularyStore: ObservableObject {
    static let shared = VocabularyStore()

    @Published private(set) var entries: [VocabularyEntry]

    private let storageKey = "vocabulary.entries"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? decoder.decode([VocabularyEntry].self, from: data) {
            entries = decoded
        } else {
            entries = []
        }
    }

    @discardableResult
    func addWord(
        original: String,
        translation: WordTranslation,
        sampleSentence: String,
        bookID: UUID,
        pageIndex: Int
    ) -> VocabularyEntry {
        let normalized = translation.normalized
        let entry = VocabularyEntry(
            id: existingEntry(withNormalized: normalized)?.id ?? UUID(),
            original: original,
            normalized: normalized,
            translation: translation.vietnamese,
            partOfSpeech: translation.partOfSpeech,
            englishDefinition: translation.englishDefinition,
            sampleSentence: sampleSentence,
            bookID: bookID,
            pageIndex: pageIndex,
            dateAdded: Date()
        )

        if let index = entries.firstIndex(where: { $0.normalized == normalized }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }

        persist()
        return entry
    }

    private func existingEntry(withNormalized normalized: String) -> VocabularyEntry? {
        entries.first { $0.normalized == normalized }
    }

    private func persist() {
        do {
            let data = try encoder.encode(entries)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to persist vocabulary: \(error)")
        }
    }
}

#if DEBUG
extension VocabularyStore {
    func debugReset() {
        entries = []
        userDefaults.removeObject(forKey: storageKey)
    }

    func debugSeedEntries() {
        debugReset()
        debugEnsureMinimumEntries(count: 12)
    }

    func debugEnsureMinimumEntries(count: Int) {
        guard entries.count < count else { return }

        let sampleWords: [(String, String, String)] = [
            ("ánh sáng", "light", "A gentle glow filled the room."),
            ("dòng sông", "river", "The river winds through the valley."),
            ("ngọn đèn", "lantern", "She raised her lantern to see."),
            ("bầu trời", "sky", "The sky shimmered with stars."),
            ("thành phố", "city", "The city hummed quietly."),
            ("niềm tin", "belief", "Their belief never wavered."),
            ("bình minh", "sunrise", "Sunrise painted the hills in gold."),
            ("mạo hiểm", "adventure", "The adventure was just beginning."),
            ("người bạn", "friend", "A friend stood beside them."),
            ("hi vọng", "hope", "Hope sparked in their hearts."),
            ("bí mật", "secret", "A secret whispered in the breeze."),
            ("bước chân", "footstep", "Footsteps echoed softly."),
            ("cánh rừng", "forest", "The forest canopy glistened."),
            ("ánh trăng", "moonlight", "Moonlight guided their path."),
            ("lửa trại", "campfire", "The campfire crackled warmly."),
        ]

        var iterator = sampleWords.makeIterator()
        let bookID = ContentProvider.shared.books.first?.id ?? UUID()

        while entries.count < count {
            let sample = iterator.next() ?? ("tình bạn", "friendship", "Friendship carried them onward.")
            let translation = WordTranslation(
                headword: sample.1,
                normalized: sample.1.replacingOccurrences(of: " ", with: "").lowercased(),
                vietnamese: sample.0,
                partOfSpeech: .noun,
                englishDefinition: sample.1.capitalized
            )

            _ = addWord(
                original: sample.0,
                translation: translation,
                sampleSentence: sample.2,
                bookID: bookID,
                pageIndex: Int.random(in: 1...12)
            )
        }
    }
}
#endif
