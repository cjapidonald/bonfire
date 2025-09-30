import SwiftUI

struct ReaderHomeView: View {
    @State private var path: [Book] = []
    @State private var difficultyFilter: DifficultyRange = .all
    @State private var topicFilter: TopicFilter = .all
    @State private var lengthFilter: BookLength = .all

    private let books = Book.sampleLibrary

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 24) {
                filterSection

                ScrollView {
                    if filteredBooks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "books.vertical")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)

                            Text("No stories match these filters yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 72)
                        .padding(.horizontal)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                            ForEach(filteredBooks) { book in
                                Button {
                                    path.append(book)
                                } label: {
                                    BookCardView(book: book)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
            .navigationTitle("Library")
            .navigationDestination(for: Book.self) { book in
                ReaderShellView(book: book)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filters")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                FilterMenu(title: "Difficulty", selection: $difficultyFilter)
                FilterMenu(title: "Topic", selection: $topicFilter)
                FilterMenu(title: "Length", selection: $lengthFilter)
            }
            .padding(.horizontal)
        }
    }

    private var filteredBooks: [Book] {
        books.filter { book in
            difficultyFilter.contains(book.difficulty) &&
            topicFilter.contains(book.topic) &&
            lengthFilter.contains(book.length)
        }
    }
}

// MARK: - Card View

private struct BookCardView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .frame(height: 120)
                .overlay(
                    Image(systemName: "book")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                )
                .frame(maxWidth: .infinity)

            Text(book.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            TagList(tags: book.tags)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

private struct TagList: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Filter Menu

private struct FilterMenu<Option: FilterOption>: View {
    let title: String
    @Binding var selection: Option

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(Array(Option.allCases)) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            HStack {
                Text(selection.menuTitle(for: title))
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemGroupedBackground))
            )
        }
        .frame(maxWidth: .infinity)
    }
}

private protocol FilterOption: CaseIterable, Identifiable, Hashable {
    var title: String { get }
    func menuTitle(for category: String) -> String
}

// MARK: - Models & Filters

private enum DifficultyRange: String, FilterOption {
    case all
    case a1a2
    case b1b2

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .a1a2:
            return "A1 – A2"
        case .b1b2:
            return "B1 – B2"
        }
    }

    func menuTitle(for category: String) -> String {
        switch self {
        case .all:
            return category
        default:
            return title
        }
    }

    func contains(_ difficulty: DifficultyLevel) -> Bool {
        switch self {
        case .all:
            return true
        case .a1a2:
            return [.a1, .a2].contains(difficulty)
        case .b1b2:
            return [.b1, .b2].contains(difficulty)
        }
    }
}

private enum TopicFilter: String, FilterOption {
    case all
    case adventure
    case science
    case culture
    case fantasy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
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

    func menuTitle(for category: String) -> String {
        switch self {
        case .all:
            return category
        default:
            return title
        }
    }

    func contains(_ topic: TopicFilter) -> Bool {
        self == .all || self == topic
    }
}

private enum BookLength: String, FilterOption {
    case all
    case short
    case medium
    case long

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .short:
            return "Short"
        case .medium:
            return "Medium"
        case .long:
            return "Long"
        }
    }

    func menuTitle(for category: String) -> String {
        switch self {
        case .all:
            return category
        default:
            return title
        }
    }

    func contains(_ length: BookLength) -> Bool {
        self == .all || self == length
    }
}

private enum DifficultyLevel: String {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
}

private struct Book: Identifiable, Hashable {
    let id: UUID
    let title: String
    let difficulty: DifficultyLevel
    let topic: TopicFilter
    let length: BookLength

    var tags: [String] {
        [difficulty.rawValue, topic.title, length.title]
    }

    init(id: UUID = UUID(), title: String, difficulty: DifficultyLevel, topic: TopicFilter, length: BookLength) {
        self.id = id
        self.title = title
        self.difficulty = difficulty
        self.topic = topic
        self.length = length
    }
}

private extension Book {
    static let sampleLibrary: [Book] = [
        Book(title: "A Walk Through the Forest", difficulty: .a1, topic: .adventure, length: .short),
        Book(title: "City Markets Around the World", difficulty: .a2, topic: .culture, length: .medium),
        Book(title: "Discovering Ocean Life", difficulty: .b1, topic: .science, length: .short),
        Book(title: "Legends of the Night Sky", difficulty: .b2, topic: .fantasy, length: .long),
        Book(title: "The Secret of the Old Lighthouse", difficulty: .b1, topic: .adventure, length: .medium),
        Book(title: "Festival of Lights", difficulty: .a2, topic: .culture, length: .short),
        Book(title: "Journey to the Mountains", difficulty: .b2, topic: .adventure, length: .long),
        Book(title: "Mysteries of Space", difficulty: .b1, topic: .science, length: .long),
        Book(title: "Gardens of the World", difficulty: .a1, topic: .culture, length: .short)
    ]
}

// MARK: - Reader Shell

private struct ReaderShellView: View {
    let book: Book

    var body: some View {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .frame(height: 180)
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "book")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Reader Placeholder")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                )

            VStack(alignment: .leading, spacing: 12) {
                Text(book.title)
                    .font(.title2.weight(.semibold))

                TagList(tags: book.tags)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Text("Content coming soon.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct ReaderHomeView_Previews: PreviewProvider {
    static var previews: some View {
        ReaderHomeView()
    }
}
#endif

