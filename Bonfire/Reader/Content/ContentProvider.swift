import Foundation

private struct Library: Codable {
    let books: [Book]
}

final class ContentProvider {
    static let shared = ContentProvider()

    private(set) var books: [Book] = []

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        self.books = loadBooks()
    }

    private func loadBooks() -> [Book] {
        guard let url = bundle.url(forResource: "the_little_river_lantern", withExtension: "json") else {
            assertionFailure("Missing bundled story resource.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let library = try decoder.decode(Library.self, from: data)
            return library.books
        } catch {
            assertionFailure("Failed to decode bundled content: \(error)")
            return []
        }
    }

    func book(withID id: Book.ID) -> Book? {
        books.first { $0.id == id }
    }
}
