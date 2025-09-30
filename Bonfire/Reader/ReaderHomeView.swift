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

    @State private var selectedLevel: Level
    @State private var selectedPageIndex: Int
    @State private var isLiquidGlassEnabled: Bool = false

    init(book: Book) {
        self.book = book
        _selectedLevel = State(initialValue: book.level)
        _selectedPageIndex = State(initialValue: book.pages.first?.index ?? 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            levelPicker
                .padding(.horizontal)
                .padding(.top, 16)

            bookViewport
                .padding(.horizontal)
                .padding(.top, 24)

            pageIndicator
                .padding(.horizontal)
                .padding(.top, 12)

            Spacer(minLength: 24)

            bottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(uiColor: .systemGroupedBackground), Color(uiColor: .secondarySystemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                EmptyView()
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.title3.weight(.semibold))

                Text("By \(book.author)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let subtitle = book.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }

                TagList(tags: book.tags)
                    .padding(.top, 8)

                if !book.summary.isEmpty {
                    Text(book.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                }
            }

            Spacer()

            ProgressRing(progress: readingProgress)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reading Level")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Reading Level", selection: $selectedLevel) {
                ForEach(Level.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var bookViewport: some View {
        TabView(selection: $selectedPageIndex) {
            ForEach(book.pages) { page in
                BookSpreadView(rightPageText: text(for: page))
                    .padding(.vertical, 8)
                    .tag(page.index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 440)
    }

    private var pageIndicator: some View {
        let position = currentPagePosition

        return HStack {
            Text("Page \(position) of \(book.pages.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(readingProgress * 100))% complete")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                ReaderControlButton(title: "Record", systemImage: "record.circle")
                    .disabled(true)

                ReaderControlButton(title: "Listen", systemImage: "headphones")
                    .disabled(true)

                LiquidGlassToggle(isOn: $isLiquidGlassEnabled)
                    .disabled(true)

                Spacer()

                Button {
                } label: {
                    Text("Submit Reading")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(true)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private var currentPagePosition: Int {
        guard let index = book.pages.firstIndex(where: { $0.index == selectedPageIndex }) else {
            return 1
        }
        return index + 1
    }

    private var readingProgress: Double {
        guard !book.pages.isEmpty else { return 0 }
        return Double(currentPagePosition) / Double(book.pages.count)
    }

    private func text(for page: Page) -> String {
        if selectedLevel == book.level {
            return page.text(for: selectedLevel)
        }

        let intro = "Level \(selectedLevel.rawValue) version coming soon."
        return intro + "\n\n" + page.text(for: selectedLevel)
    }
}

private struct BookSpreadView: View {
    let rightPageText: String

    var body: some View {
        GeometryReader { geometry in
            let spreadWidth = geometry.size.width

            HStack(spacing: 0) {
                BookPageContainer {
                    ArtworkPlaceholder()
                }
                .frame(width: spreadWidth / 2)

                Rectangle()
                    .fill(Color.black.opacity(0.06))
                    .frame(width: 1, height: geometry.size.height * 0.8)

                BookPageContainer {
                    RightPageContent(text: rightPageText)
                }
                .frame(width: spreadWidth / 2)
            }
            .frame(width: spreadWidth, height: geometry.size.height)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 16)
            .padding(.horizontal, spreadWidth * 0.05)
        }
    }
}

private struct BookPageContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ArtworkPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(Color.secondary.opacity(0.6))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                )
                .frame(maxWidth: .infinity)
                .frame(height: 180)

            Text("Artwork Placeholder")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct RightPageContent: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }
}

private struct ReaderControlButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        Button {
        } label: {
            Label(title, systemImage: systemImage)
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
    }
}

private struct LiquidGlassToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label("Liquid Glass", systemImage: "sparkles")
                .font(.callout.weight(.semibold))
        }
        .toggleStyle(.switch)
    }
}

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        let displayProgress = min(max(progress, 0), 1)

        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 6)

            Circle()
                .trim(from: 0, to: displayProgress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(displayProgress * 100))%")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .frame(width: 56, height: 56)
    }
}

private extension Page {
    func text(for level: Level) -> String {
        // Future stories may ship multiple difficulty variants; for now we default to the primary text.
        primaryText
    }
}

#if DEBUG
struct ReaderHomeView_Previews: PreviewProvider {
    static var previews: some View {
        ReaderHomeView()
    }
}
#endif

