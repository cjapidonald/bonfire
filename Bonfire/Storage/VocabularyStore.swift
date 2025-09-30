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
