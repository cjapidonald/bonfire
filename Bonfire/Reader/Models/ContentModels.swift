import Foundation

enum Level: String, Codable, CaseIterable, Identifiable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"

    var id: String { rawValue }
}

enum BookTopic: String, Codable, CaseIterable, Identifiable {
    case adventure
    case science
    case culture
    case fantasy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .adventure:
            return "Adventure"
        case .science:
            return "Science"
        case .culture:
            return "Culture"
        case .fantasy:
            return "Fantasy"
        }
    }
}

enum BookLength: String, Codable, CaseIterable, Identifiable {
    case short
    case medium
    case long

    var id: String { rawValue }

    var title: String {
        switch self {
        case .short:
            return "Short"
        case .medium:
            return "Medium"
        case .long:
            return "Long"
        }
    }
}

struct TextVariant: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case original
        case translation
        case phonetic
    }

    let id: String
    let kind: Kind
    let languageCode: String
    let content: String

    init(id: String = UUID().uuidString, kind: Kind, languageCode: String, content: String) {
        self.id = id
        self.kind = kind
        self.languageCode = languageCode
        self.content = content
    }
}

extension TextVariant.Kind {
    var displayName: String {
        switch self {
        case .original:
            return "Original"
        case .translation:
            return "Translation"
        case .phonetic:
            return "Pronunciation"
        }
    }
}

struct DictionaryEntry: Codable, Identifiable, Hashable {
    let term: String
    let definition: String
    let partOfSpeech: String
    let example: String
    let level: Level

    var id: String { term }
}

struct Page: Codable, Identifiable, Hashable {
    let index: Int
    let variants: [TextVariant]
    let dictionaryEntries: [DictionaryEntry]

    var id: Int { index }

    var primaryText: String {
        if let original = variants.first(where: { $0.kind == .original }) {
            return original.content
        }
        return variants.first?.content ?? ""
    }
}

struct Book: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String?
    let author: String
    let summary: String
    let level: Level
    let topic: BookTopic
    let length: BookLength
    let pages: [Page]
    let dictionary: [DictionaryEntry]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        author: String,
        summary: String,
        level: Level,
        topic: BookTopic,
        length: BookLength,
        pages: [Page],
        dictionary: [DictionaryEntry]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.author = author
        self.summary = summary
        self.level = level
        self.topic = topic
        self.length = length
        self.pages = pages
        self.dictionary = dictionary
    }

    var tags: [String] {
        [level.rawValue, topic.title, length.title]
    }
}

struct ReadingSession: Codable, Identifiable, Hashable {
    let id: UUID
    let bookID: Book.ID
    let startedAt: Date
    let duration: TimeInterval
    let completedPageIndices: [Int]

    init(
        id: UUID = UUID(),
        bookID: Book.ID,
        startedAt: Date,
        duration: TimeInterval,
        completedPageIndices: [Int] = []
    ) {
        self.id = id
        self.bookID = bookID
        self.startedAt = startedAt
        self.duration = duration
        self.completedPageIndices = completedPageIndices
    }
}

struct WordProgress: Codable, Identifiable, Hashable {
    let id: UUID
    let term: String
    var encounters: Int
    var mastery: Double
    var lastReviewed: Date?

    init(id: UUID = UUID(), term: String, encounters: Int = 0, mastery: Double = 0, lastReviewed: Date? = nil) {
        self.id = id
        self.term = term
        self.encounters = encounters
        self.mastery = mastery
        self.lastReviewed = lastReviewed
    }
}

struct BookProgress: Codable, Identifiable, Hashable {
    let id: UUID
    let bookID: Book.ID
    var currentPageIndex: Int
    var isCompleted: Bool
    var wordProgress: [WordProgress]
    var lastReadAt: Date?
    var visitedPageIndices: Set<Int>

    init(
        id: UUID = UUID(),
        bookID: Book.ID,
        currentPageIndex: Int = 0,
        isCompleted: Bool = false,
        wordProgress: [WordProgress] = [],
        lastReadAt: Date? = nil,
        visitedPageIndices: Set<Int> = []
    ) {
        self.id = id
        self.bookID = bookID
        self.currentPageIndex = currentPageIndex
        self.isCompleted = isCompleted
        self.wordProgress = wordProgress
        self.lastReadAt = lastReadAt
        self.visitedPageIndices = visitedPageIndices
    }
}

extension Page {
    func text(for level: Level) -> String {
        // Future stories may ship multiple difficulty variants; for now we default to the primary text.
        primaryText
    }

    func wordCount(for level: Level) -> Int {
        let components = text(for: level)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return components.count
    }
}
