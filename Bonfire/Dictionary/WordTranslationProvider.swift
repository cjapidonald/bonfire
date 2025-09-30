import Foundation

final class WordTranslationProvider {
    struct LexiconEntry {
        let translation: String
        let partOfSpeech: WordPartOfSpeech
    }

    static let shared = WordTranslationProvider()

    private let lexicon: [String: LexiconEntry]
    private let fallbackTranslation = "Xin lỗi, chúng tôi chưa có bản dịch cho từ này."
    private let cacheLimit = 50

    private struct CacheKey: Hashable {
        let bookID: Book.ID
        let token: String
    }

    private static let irregularLemmas: [String: String] = [
        "children": "child",
        "mice": "mouse",
        "geese": "goose",
        "men": "man",
        "women": "woman",
        "teeth": "tooth",
        "feet": "foot",
        "did": "do",
        "done": "do",
        "went": "go",
        "gone": "go",
        "better": "good",
        "best": "good",
        "worse": "bad",
        "worst": "bad",
        "ran": "run",
        "saw": "see",
        "seen": "see",
        "taught": "teach",
        "built": "build",
        "felt": "feel"
    ]

    private var cache: [CacheKey: WordTranslation]
    private var cacheOrder: [CacheKey]

    init() {
        lexicon = [
            "a": LexiconEntry(translation: "một", partOfSpeech: .article),
            "among": LexiconEntry(translation: "giữa", partOfSpeech: .preposition),
            "and": LexiconEntry(translation: "và", partOfSpeech: .conjunction),
            "built": LexiconEntry(translation: "xây dựng", partOfSpeech: .verb),
            "by": LexiconEntry(translation: "bởi", partOfSpeech: .preposition),
            "every": LexiconEntry(translation: "mỗi", partOfSpeech: .determiner),
            "father": LexiconEntry(translation: "cha", partOfSpeech: .noun),
            "felt": LexiconEntry(translation: "cảm thấy", partOfSpeech: .verb),
            "festival": LexiconEntry(translation: "lễ hội", partOfSpeech: .noun),
            "fisherman": LexiconEntry(translation: "ngư dân", partOfSpeech: .noun),
            "flower": LexiconEntry(translation: "bông hoa", partOfSpeech: .noun),
            "for": LexiconEntry(translation: "cho", partOfSpeech: .preposition),
            "gentle": LexiconEntry(translation: "hiền hòa", partOfSpeech: .adjective),
            "glowing": LexiconEntry(translation: "sáng rực", partOfSpeech: .adjective),
            "he": LexiconEntry(translation: "ông ấy", partOfSpeech: .pronoun),
            "help": LexiconEntry(translation: "giúp đỡ", partOfSpeech: .verb),
            "her": LexiconEntry(translation: "của cô ấy", partOfSpeech: .pronoun),
            "him": LexiconEntry(translation: "ông ấy", partOfSpeech: .pronoun),
            "home": LexiconEntry(translation: "nhà", partOfSpeech: .noun),
            "house": LexiconEntry(translation: "ngôi nhà", partOfSpeech: .noun),
            "hung": LexiconEntry(translation: "treo", partOfSpeech: .verb),
            "in": LexiconEntry(translation: "trong", partOfSpeech: .preposition),
            "it": LexiconEntry(translation: "nó", partOfSpeech: .pronoun),
            "lantern": LexiconEntry(translation: "đèn lồng", partOfSpeech: .noun),
            "lanterns": LexiconEntry(translation: "những chiếc đèn lồng", partOfSpeech: .noun),
            "late": LexiconEntry(translation: "muộn", partOfSpeech: .adverb),
            "led": LexiconEntry(translation: "dẫn đường", partOfSpeech: .verb),
            "light": LexiconEntry(translation: "ánh sáng", partOfSpeech: .noun),
            "lights": LexiconEntry(translation: "những ánh đèn", partOfSpeech: .noun),
            "like": LexiconEntry(translation: "như", partOfSpeech: .preposition),
            "lit": LexiconEntry(translation: "thắp sáng", partOfSpeech: .verb),
            "lived": LexiconEntry(translation: "sống", partOfSpeech: .verb),
            "lotus": LexiconEntry(translation: "hoa sen", partOfSpeech: .noun),
            "mai": LexiconEntry(translation: "Mai", partOfSpeech: .properNoun),
            "month": LexiconEntry(translation: "tháng", partOfSpeech: .noun),
            "night": LexiconEntry(translation: "đêm", partOfSpeech: .noun),
            "on": LexiconEntry(translation: "trên", partOfSpeech: .preposition),
            "people": LexiconEntry(translation: "mọi người", partOfSpeech: .noun),
            "proud": LexiconEntry(translation: "tự hào", partOfSpeech: .adjective),
            "river": LexiconEntry(translation: "dòng sông", partOfSpeech: .noun),
            "riverside": LexiconEntry(translation: "ven sông", partOfSpeech: .adjective),
            "rowed": LexiconEntry(translation: "chèo thuyền", partOfSpeech: .verb),
            "saw": LexiconEntry(translation: "nhìn thấy", partOfSpeech: .verb),
            "searching": LexiconEntry(translation: "tìm kiếm", partOfSpeech: .verb),
            "shaped": LexiconEntry(translation: "có hình dạng", partOfSpeech: .adjective),
            "she": LexiconEntry(translation: "cô ấy", partOfSpeech: .pronoun),
            "small": LexiconEntry(translation: "nhỏ bé", partOfSpeech: .adjective),
            "smiled": LexiconEntry(translation: "mỉm cười", partOfSpeech: .verb),
            "soft": LexiconEntry(translation: "êm dịu", partOfSpeech: .adjective),
            "straight": LexiconEntry(translation: "thẳng tắp", partOfSpeech: .adverb),
            "thank": LexiconEntry(translation: "cảm ơn", partOfSpeech: .verb),
            "the": LexiconEntry(translation: "(mạo từ xác định)", partOfSpeech: .article),
            "their": LexiconEntry(translation: "của họ", partOfSpeech: .determiner),
            "to": LexiconEntry(translation: "để", partOfSpeech: .preposition),
            "town": LexiconEntry(translation: "thị trấn", partOfSpeech: .noun),
            "wanted": LexiconEntry(translation: "muốn", partOfSpeech: .verb),
            "was": LexiconEntry(translation: "là", partOfSpeech: .verb),
            "water": LexiconEntry(translation: "nước", partOfSpeech: .noun),
            "when": LexiconEntry(translation: "khi", partOfSpeech: .conjunction)
        ]
        cache = [:]
        cacheOrder = []
    }

    func translation(for selection: WordDetectingTextView.WordSelection, in book: Book) -> WordTranslation {
        let normalized = selection.normalized
        let cacheKey = CacheKey(bookID: book.id, token: normalized)

        if let cached = translationFromCache(for: cacheKey) {
            return cached
        }

        let dictionaryIndex = book.dictionary.reduce(into: [String: DictionaryEntry]()) { result, entry in
            let key = entry.term.lowercased()
            if result[key] == nil {
                result[key] = entry
            }
        }

        let lookupResult = resolveLookup(for: normalized, dictionaryIndex: dictionaryIndex)

        let headword = lookupResult?.dictionaryEntry?.term
            ?? lookupResult?.matchedToken
            ?? selection.original

        let partOfSpeech: WordPartOfSpeech
        if let lexiconEntry = lookupResult?.lexiconEntry {
            partOfSpeech = lexiconEntry.partOfSpeech
        } else if let dictionaryEntry = lookupResult?.dictionaryEntry {
            partOfSpeech = WordPartOfSpeech(label: dictionaryEntry.partOfSpeech)
        } else {
            partOfSpeech = .unknown
        }

        let translation: String
        if let lexiconEntry = lookupResult?.lexiconEntry {
            translation = lexiconEntry.translation
        } else {
            translation = fallbackTranslation
        }
        let englishDefinition = lookupResult?.dictionaryEntry?.definition

        let wordTranslation = WordTranslation(
            headword: headword,
            normalized: normalized,
            vietnamese: translation,
            partOfSpeech: partOfSpeech,
            englishDefinition: englishDefinition
        )

        cache(translation: wordTranslation, for: cacheKey)

        return wordTranslation
    }

    private func translationFromCache(for key: CacheKey) -> WordTranslation? {
        guard let translation = cache[key] else { return nil }
        promoteCacheKey(key)
        return translation
    }

    private func cache(translation: WordTranslation, for key: CacheKey) {
        cache[key] = translation
        promoteCacheKey(key)

        if cacheOrder.count > cacheLimit, let removed = cacheOrder.popLast() {
            cache.removeValue(forKey: removed)
        }
    }

    private func promoteCacheKey(_ key: CacheKey) {
        cacheOrder.removeAll { $0 == key }
        cacheOrder.insert(key, at: 0)
    }

    private func resolveLookup(
        for token: String,
        dictionaryIndex: [String: DictionaryEntry]
    ) -> LookupResult? {
        guard !token.isEmpty else { return nil }

        if let direct = directLookup(for: token, dictionaryIndex: dictionaryIndex) {
            return direct
        }

        for lemma in lemmaCandidates(for: token) {
            if let result = directLookup(for: lemma, dictionaryIndex: dictionaryIndex) {
                return result
            }
        }

        return nil
    }

    private func directLookup(
        for token: String,
        dictionaryIndex: [String: DictionaryEntry]
    ) -> LookupResult? {
        if let lexiconEntry = lexicon[token] {
            return LookupResult(
                matchedToken: token,
                lexiconEntry: lexiconEntry,
                dictionaryEntry: dictionaryIndex[token]
            )
        }

        if let dictionaryEntry = dictionaryIndex[token] {
            return LookupResult(
                matchedToken: dictionaryEntry.term,
                lexiconEntry: lexicon[dictionaryEntry.term.lowercased()],
                dictionaryEntry: dictionaryEntry
            )
        }

        return nil
    }

    private func lemmaCandidates(for token: String) -> [String] {
        var seen: Set<String> = [token]
        var queue: [String] = [token]
        var results: [String] = []

        while !queue.isEmpty {
            let form = queue.removeFirst()
            for candidate in transformations(of: form) {
                guard !candidate.isEmpty, !seen.contains(candidate) else { continue }
                seen.insert(candidate)
                queue.append(candidate)
                results.append(candidate)
            }
        }

        results.removeAll { $0 == token }
        return results
    }

    private func transformations(of form: String) -> [String] {
        let normalizedForm = form.lowercased()
        var candidates: Set<String> = []

        func append(_ value: String) {
            let trimmed = value.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
            guard !trimmed.isEmpty else { return }
            candidates.insert(trimmed.lowercased())
        }

        if let irregular = Self.irregularLemmas[normalizedForm] {
            append(irregular)
        }

        let apostropheNormalized = normalizedForm.replacingOccurrences(of: "’", with: "'")
        if apostropheNormalized.hasSuffix("'s") {
            append(String(apostropheNormalized.dropLast(2)))
        }
        if apostropheNormalized.hasSuffix("s'") {
            append(String(apostropheNormalized.dropLast(2)))
        }
        if apostropheNormalized.hasSuffix("'") {
            append(String(apostropheNormalized.dropLast()))
        }

        if normalizedForm.hasSuffix("ies"), normalizedForm.count > 3 {
            append(String(normalizedForm.dropLast(3)) + "y")
        }

        if normalizedForm.hasSuffix("ied"), normalizedForm.count > 3 {
            append(String(normalizedForm.dropLast(3)) + "y")
        }

        if normalizedForm.hasSuffix("es"), normalizedForm.count > 2 {
            append(String(normalizedForm.dropLast(2)))
        }

        if normalizedForm.hasSuffix("s"), normalizedForm.count > 1 {
            append(String(normalizedForm.dropLast()))
        }

        if normalizedForm.hasSuffix("ing"), normalizedForm.count > 4 {
            let base = String(normalizedForm.dropLast(3))
            append(base)
            if let droppedDouble = dropTrailingDoubleConsonant(from: base) {
                append(droppedDouble)
            }
            append(base + "e")
        }

        if normalizedForm.hasSuffix("ed"), normalizedForm.count > 3 {
            let base = String(normalizedForm.dropLast(2))
            append(base)
            if let droppedDouble = dropTrailingDoubleConsonant(from: base) {
                append(droppedDouble)
            }
            append(base + "e")
        }

        if normalizedForm.hasSuffix("er"), normalizedForm.count > 3 {
            append(String(normalizedForm.dropLast(2)))
        }

        if normalizedForm.hasSuffix("est"), normalizedForm.count > 4 {
            append(String(normalizedForm.dropLast(3)))
        }

        if normalizedForm.hasSuffix("ly"), normalizedForm.count > 2 {
            append(String(normalizedForm.dropLast(2)))
        }

        return Array(candidates)
    }

    private func dropTrailingDoubleConsonant(from word: String) -> String? {
        guard word.count >= 2 else { return nil }
        let lastIndex = word.index(before: word.endIndex)
        let secondLastIndex = word.index(before: lastIndex)
        let lastCharacter = word[lastIndex]
        let secondLastCharacter = word[secondLastIndex]

        guard lastCharacter == secondLastCharacter else { return nil }
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        guard !vowels.contains(lastCharacter) else { return nil }

        return String(word[..<lastIndex])
    }

    private struct LookupResult {
        let matchedToken: String
        let lexiconEntry: LexiconEntry?
        let dictionaryEntry: DictionaryEntry?
    }
}
