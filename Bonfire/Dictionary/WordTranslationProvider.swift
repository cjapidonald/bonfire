import Foundation

final class WordTranslationProvider {
    struct LexiconEntry {
        let translation: String
        let partOfSpeech: WordPartOfSpeech
    }

    static let shared = WordTranslationProvider()

    private let lexicon: [String: LexiconEntry]

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
    }

    func translation(for selection: WordDetectingTextView.WordSelection, in book: Book) -> WordTranslation {
        let normalized = selection.normalized
        let dictionaryEntry = book.dictionary.first { $0.term.lowercased() == normalized }
        let lexiconEntry = lexicon[normalized]
        let partOfSpeech: WordPartOfSpeech
        if let lexiconEntry {
            partOfSpeech = lexiconEntry.partOfSpeech
        } else if let dictionaryEntry {
            partOfSpeech = WordPartOfSpeech(label: dictionaryEntry.partOfSpeech)
        } else {
            partOfSpeech = .unknown
        }

        let translation = lexiconEntry?.translation ?? selection.original
        let headword = dictionaryEntry?.term ?? selection.original
        let englishDefinition = dictionaryEntry?.definition

        return WordTranslation(
            headword: headword,
            normalized: normalized,
            vietnamese: translation,
            partOfSpeech: partOfSpeech,
            englishDefinition: englishDefinition
        )
    }
}
