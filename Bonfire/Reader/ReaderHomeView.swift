import SwiftUI

struct ReaderHomeView: View {
    @State private var path: [Book] = []
    @State private var levelFilter: LevelFilter = .all
    @State private var topicFilter: TopicFilter = .all
    @State private var lengthFilter: LengthFilter = .all

    private let contentProvider = ContentProvider.shared

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
                FilterMenu(title: "Difficulty", selection: $levelFilter)
                FilterMenu(title: "Topic", selection: $topicFilter)
                FilterMenu(title: "Length", selection: $lengthFilter)
            }
            .padding(.horizontal)
        }
    }

    private var filteredBooks: [Book] {
        contentProvider.books.filter { book in
            levelFilter.contains(book.level) &&
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

private enum LevelFilter: String, FilterOption {
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

    func contains(_ level: Level) -> Bool {
        switch self {
        case .all:
            return true
        case .a1a2:
            return [.a1, .a2].contains(level)
        case .b1b2:
            return [.b1, .b2].contains(level)
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

    func contains(_ topic: BookTopic) -> Bool {
        switch self {
        case .all:
            return true
        case .adventure:
            return topic == .adventure
        case .science:
            return topic == .science
        case .culture:
            return topic == .culture
        case .fantasy:
            return topic == .fantasy
        }
    }
}

private enum LengthFilter: String, FilterOption {
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
        switch self {
        case .all:
            return true
        case .short:
            return length == .short
        case .medium:
            return length == .medium
        case .long:
            return length == .long
        }
    }
}

// MARK: - Reader Shell

private struct ReaderShellView: View {
    let book: Book
    @State private var selectedPageIndex: Int = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("By \(book.author)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let subtitle = book.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                TagList(tags: book.tags)

                Text(book.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TabView(selection: $selectedPageIndex) {
                ForEach(book.pages) { page in
                    PageReaderView(page: page)
                        .tag(page.index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            .frame(maxWidth: .infinity)

            Text("Page \(selectedPageIndex) of \(book.pages.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedPageIndex = book.pages.first?.index ?? 1
        }
    }
}

private struct PageReaderView: View {
    let page: Page

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Page \(page.index)")
                    .font(.title3.weight(.semibold))

                ForEach(page.variants) { variant in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(variant.kind.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(variant.content)
                            .font(variant.kind == .original ? .body : .callout)
                    }
                }

                if !page.dictionaryEntries.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Words")
                            .font(.headline)

                        ForEach(page.dictionaryEntries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.term.capitalized)
                                    .font(.subheadline.weight(.semibold))

                                Text(entry.definition)
                                    .font(.footnote)

                                Text(entry.example)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct ReaderHomeView_Previews: PreviewProvider {
    static var previews: some View {
        ReaderHomeView()
    }
}
#endif

