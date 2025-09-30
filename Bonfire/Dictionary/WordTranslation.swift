import Foundation

enum WordPartOfSpeech: String, Codable, CaseIterable {
    case noun
    case verb
    case adjective
    case adverb
    case pronoun
    case preposition
    case conjunction
    case article
    case determiner
    case phrase
    case expression
    case properNoun = "proper_noun"
    case unknown

    init(label: String) {
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "noun":
            self = .noun
        case "verb":
            self = .verb
        case "adjective":
            self = .adjective
        case "adverb":
            self = .adverb
        case "pronoun":
            self = .pronoun
        case "preposition":
            self = .preposition
        case "conjunction":
            self = .conjunction
        case "article":
            self = .article
        case "determiner":
            self = .determiner
        case "phrase":
            self = .phrase
        case "expression":
            self = .expression
        case "proper noun", "proper_noun":
            self = .properNoun
        default:
            self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .properNoun:
            return "Proper noun"
        case .unknown:
            return "Unknown"
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

struct WordTranslation: Equatable {
    let headword: String
    let normalized: String
    let vietnamese: String
    let partOfSpeech: WordPartOfSpeech
    let englishDefinition: String?
}
