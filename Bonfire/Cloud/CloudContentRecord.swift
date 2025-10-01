import CloudKit

/// CloudKit record type names used for Public database content.
enum CloudContentRecordType {
    static let book = "Book"
    static let page = "Page"
    static let textVariant = "TextVariant"
    static let dictionaryEntry = "DictionaryEntry"
}

/// Field keys for the `Book` record type stored in the Public database.
enum CloudBookFields {
    static let title = "title"
    static let subtitle = "subtitle"
    static let author = "author"
    static let summary = "summary"
    static let level = "level"
    static let topic = "topic"
    static let length = "length"
    static let pageCount = "pageCount"
}

/// Field keys for the `Page` record type.
enum CloudPageFields {
    static let book = "book"
    static let index = "index"
    static let estimatedWordCount = "estimatedWordCount"
}

/// Field keys for the `TextVariant` record type.
enum CloudTextVariantFields {
    static let page = "page"
    static let kind = "kind"
    static let languageCode = "languageCode"
    static let content = "content"
    static let displayOrder = "displayOrder"
}

/// Field keys for the `DictionaryEntry` record type.
enum CloudDictionaryEntryFields {
    static let book = "book"
    static let lemma = "lemma"
    static let term = "term"
    static let definition = "definition"
    static let partOfSpeech = "partOfSpeech"
    static let example = "example"
    static let level = "level"
    static let pageIndex = "pageIndex"
}

extension CKRecord {
    /// Convenience accessor for resolving a book reference from a page or dictionary entry.
    func bookReference(forKey key: String) -> CKRecord.Reference? {
        object(forKey: key) as? CKRecord.Reference
    }
}
