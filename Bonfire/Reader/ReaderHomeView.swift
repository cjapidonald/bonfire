import Foundation
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

    @StateObject private var readerState: ReaderState
    @State private var selectedPageIndex: Int
    @State private var isLiquidGlassEnabled: Bool = false
    @State private var lastWordInteractionDescription: String?
    @ObservedObject private var vocabularyStore = VocabularyStore.shared
    @State private var activePopover: WordPopoverPresentation?

    private let translationProvider = WordTranslationProvider.shared

    init(book: Book) {
        self.book = book
        _readerState = StateObject(wrappedValue: ReaderState(book: book))
        _selectedPageIndex = State(initialValue: book.pages.first?.index ?? 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            difficultyGear
                .padding(.horizontal)
                .padding(.top, 16)

            bookViewport
                .padding(.horizontal)
                .padding(.top, 24)

            pageIndicator
                .padding(.horizontal)
                .padding(.top, 12)

            if let interactionDescription = lastWordInteractionDescription {
                Text(interactionDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

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

    private var difficultyGear: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reading Level")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            DifficultyGearControl(level: Binding(
                get: { readerState.level },
                set: { readerState.level = $0 }
            ))
        }
    }

    private var bookViewport: some View {
        TabView(selection: $selectedPageIndex) {
            ForEach(book.pages) { page in
                BookSpreadView(
                    page: page,
                    text: text(for: page),
                    activePopover: $activePopover,
                    isLiquidGlassEnabled: isLiquidGlassEnabled,
                    onSingleTap: { selection in
                        handleSingleTap(on: page, selection: selection)
                    },
                    onDoubleTap: { selection in
                        handleDoubleTap(on: page, selection: selection)
                    },
                    onAddToVocabulary: { presentation in
                        addWordToVocabulary(from: presentation, source: "popover")
                    }
                )
                .padding(.vertical, 8)
                .tag(page.index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 440)
        .onChange(of: selectedPageIndex) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                activePopover = nil
            }
        }
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
        let currentLevel = readerState.level

        if currentLevel == book.level {
            return page.text(for: currentLevel)
        }

        let intro = "Level \(currentLevel.rawValue) version coming soon."
        return intro + "\n\n" + page.text(for: currentLevel)
    }

    private func handleSingleTap(on page: Page, selection: WordDetectingTextView.WordSelection) {
        let translation = translationProvider.translation(for: selection, in: book)
        let sample = sampleSentence(for: selection, on: page)
        let presentation = WordPopoverPresentation(
            pageIndex: page.index,
            selection: selection,
            translation: translation,
            sampleSentence: sample
        )

        withAnimation(.spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0.2)) {
            activePopover = presentation
        }

        lastWordInteractionDescription = "“\(selection.original)” → “\(translation.vietnamese)” • Tap Add to save."
    }

    private func handleDoubleTap(on page: Page, selection: WordDetectingTextView.WordSelection) {
        let translation = translationProvider.translation(for: selection, in: book)
        let sample = sampleSentence(for: selection, on: page)
        let presentation = WordPopoverPresentation(
            pageIndex: page.index,
            selection: selection,
            translation: translation,
            sampleSentence: sample
        )

        addWordToVocabulary(from: presentation, source: "double_tap")
    }

    private func addWordToVocabulary(from presentation: WordPopoverPresentation, source: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            activePopover = nil
        }

        let entry = vocabularyStore.addWord(
            original: presentation.selection.original,
            translation: presentation.translation,
            sampleSentence: presentation.sampleSentence,
            bookID: book.id,
            pageIndex: presentation.pageIndex
        )

        if source == "double_tap" {
            lastWordInteractionDescription = "✓ “\(entry.original)” saved to Vocabulary."
        } else {
            lastWordInteractionDescription = "Added “\(entry.original)” to Vocabulary."
        }

        AnalyticsLogger.shared.log(
            event: "vocab_added",
            metadata: [
                "term": entry.normalized,
                "book_id": book.id.uuidString,
                "page_index": String(presentation.pageIndex),
                "source": source
            ]
        )
    }

    private func sampleSentence(for selection: WordDetectingTextView.WordSelection, on page: Page) -> String {
        let pageText = text(for: page)
        if let sentence = sentenceContaining(word: selection.normalized, in: pageText) {
            return sentence
        }

        if let sentence = sentenceContaining(word: selection.original, in: pageText) {
            return sentence
        }

        let trimmed = pageText
            .components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed ?? pageText
    }

    private func sentenceContaining(word: String, in text: String) -> String? {
        guard !word.isEmpty else { return nil }

        let escaped = NSRegularExpression.escapedPattern(for: word)
        let pattern = "([^.!?]*\\b\(escaped)\\b[^.!?]*[.!?])"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let swiftRange = Range(match.range, in: text) else {
            return nil
        }

        return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DifficultyGearControl: View {
    @Binding var level: Level

    @State private var activeIndex: Int = 0
    @State private var gearRotation: Double = 0

    private let levels = Level.allCases
    private let knobSize: CGFloat = 92

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Difficulty Gear")
                        .font(.headline)

                    Text("Adjust the story to match your reading comfort.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(level.rawValue)
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentColor.opacity(0.15))
                    )
            }

            HStack(alignment: .center, spacing: 24) {
                sliderColumn
                labelsColumn
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .onAppear { syncState(animated: false) }
        .onChange(of: level) { _ in
            syncState(animated: true)
        }
    }

    private var sliderColumn: some View {
        GeometryReader { proxy in
            let travel = max(proxy.size.height - knobSize, 1)
            let step = travel / CGFloat(max(levels.count - 1, 1))

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.35),
                                Color.black.opacity(0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 28)
                    .frame(maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                ForEach(levels.indices, id: \.self) { index in
                    tick(isActive: index == activeIndex)
                        .offset(y: step * CGFloat(index))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            select(levels[index])
                        }
                }

                gearKnob
                    .frame(width: knobSize, height: knobSize)
                    .offset(y: step * CGFloat(activeIndex))
                    .animation(.spring(response: 0.7, dampingFraction: 0.75, blendDuration: 0.25), value: activeIndex)
                    .animation(.easeInOut(duration: 0.6), value: gearRotation)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let offset = min(max(value.location.y - knobSize / 2, 0), travel)
                                let stepSize = step == 0 ? 1 : step
                                let index = Int(round(offset / stepSize))
                                let clampedIndex = min(max(index, 0), levels.count - 1)
                                select(levels[clampedIndex])
                            }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: knobSize, height: 240)
    }

    private var labelsColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(levels.indices, id: \.self) { index in
                let option = levels[index]

                Button {
                    select(option)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.rawValue)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(index == activeIndex ? Color.primary : Color.secondary)

                        Text(description(for: option))
                            .font(.caption)
                            .foregroundStyle(index == activeIndex ? Color.accentColor : Color.secondary.opacity(0.7))
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                if index != levels.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: 240, alignment: .top)
    }

    private func tick(isActive: Bool) -> some View {
        Capsule()
            .fill(Color.accentColor.opacity(isActive ? 0.8 : 0.25))
            .frame(width: 36, height: 4)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.accentColor.opacity(isActive ? 0.5 : 0), radius: 8, x: 0, y: 0)
    }

    private var gearKnob: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .blur(radius: 14)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )

            Image(systemName: "gearshape.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .rotationEffect(.degrees(gearRotation))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 10)
    }

    private func select(_ newLevel: Level) {
        guard newLevel != level else { return }
        level = newLevel
    }

    private func description(for level: Level) -> String {
        switch level {
        case .a1:
            return "Starter vocabulary"
        case .a2:
            return "Beginner comfort"
        case .b1:
            return "Growing confidence"
        case .b2:
            return "Advanced challenge"
        }
    }

    private func syncState(animated: Bool) {
        guard let index = levels.firstIndex(of: level) else { return }

        let updates = {
            activeIndex = index
            gearRotation = Double(index) * 90
        }

        if animated {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75, blendDuration: 0.25)) {
                updates()
            }
        } else {
            updates()
        }
    }
}

private struct BookSpreadView: View {
    let page: Page
    let text: String
    @Binding var activePopover: WordPopoverPresentation?
    var isLiquidGlassEnabled: Bool
    var onSingleTap: (WordDetectingTextView.WordSelection) -> Void = { _ in }
    var onDoubleTap: (WordDetectingTextView.WordSelection) -> Void = { _ in }
    var onAddToVocabulary: (WordPopoverPresentation) -> Void = { _ in }

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
                    RightPageContent(
                        pageIndex: page.index,
                        text: text,
                        activePopover: $activePopover,
                        isLiquidGlassEnabled: isLiquidGlassEnabled,
                        onSingleTap: onSingleTap,
                        onDoubleTap: onDoubleTap,
                        onAddToVocabulary: onAddToVocabulary
                    )
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
    let pageIndex: Int
    let text: String
    @Binding var activePopover: WordPopoverPresentation?
    var isLiquidGlassEnabled: Bool
    var onSingleTap: (WordDetectingTextView.WordSelection) -> Void
    var onDoubleTap: (WordDetectingTextView.WordSelection) -> Void
    var onAddToVocabulary: (WordPopoverPresentation) -> Void

    @State private var textViewSize: CGSize = .zero
    @State private var popoverSize: CGSize = .zero
    @State private var glassOrigin: CGPoint = .zero
    @State private var glassSize: CGSize = .zero
    @State private var isGlassInitialized: Bool = false
    @State private var isDraggingGlass: Bool = false
    @State private var dragStartOrigin: CGPoint = .zero

    var body: some View {
        ScrollView {
            WordDetectingTextView(
                text: text,
                onSingleTap: onSingleTap,
                onDoubleTap: onDoubleTap
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: TextViewSizePreferenceKey.self, value: proxy.size)
                }
            )
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    if isLiquidGlassEnabled, glassSize != .zero {
                        LiquidGlassBlobView(size: glassSize, isDragging: isDraggingGlass)
                            .offset(x: glassOrigin.x, y: glassOrigin.y)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if !isDraggingGlass {
                                            isDraggingGlass = true
                                            dragStartOrigin = glassOrigin
                                        }

                                        let proposed = CGPoint(
                                            x: dragStartOrigin.x + value.translation.width,
                                            y: dragStartOrigin.y + value.translation.height
                                        )

                                        glassOrigin = clampedOrigin(for: proposed, in: textViewSize, blobSize: glassSize)
                                    }
                                    .onEnded { _ in
                                        isDraggingGlass = false
                                    }
                            )
                            .accessibilityHidden(true)
                            .transition(.opacity.combined(with: .scale))
                    }

                    if let presentation = activePopover, presentation.pageIndex == pageIndex {
                        WordTranslationPopover(presentation: presentation) {
                            onAddToVocabulary(presentation)
                        }
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: PopoverSizePreferenceKey.self, value: proxy.size)
                            }
                        )
                        .offset(popoverOffset(for: presentation))
                        .transition(.scale(scale: 0.95, anchor: .top))
                    }
                }
            }
        }
        .onPreferenceChange(TextViewSizePreferenceKey.self) { textViewSize = $0 }
        .onPreferenceChange(PopoverSizePreferenceKey.self) { popoverSize = $0 }
        .scrollIndicators(.hidden)
        .animation(.spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0.15), value: activePopover?.id)
        .onChange(of: textViewSize) { newSize in
            synchronizeGlassFrame(with: newSize)
        }
        .onChange(of: isLiquidGlassEnabled) { isEnabled in
            if isEnabled {
                synchronizeGlassFrame(with: textViewSize)
            } else {
                isDraggingGlass = false
            }
        }
        .onAppear {
            synchronizeGlassFrame(with: textViewSize)
        }
    }

    private func popoverOffset(for presentation: WordPopoverPresentation) -> CGSize {
        guard textViewSize != .zero else { return .zero }

        let margin: CGFloat = 8
        let anchor = presentation.anchorRect
        let width = popoverSize.width
        let availableWidth = max(textViewSize.width - width, 0)
        let centeredX = anchor.midX - width / 2
        let clampedX = max(0, min(centeredX, availableWidth))

        let topSpace = max(anchor.minY, 0)

        var y: CGFloat
        if popoverSize == .zero {
            y = max(anchor.minY - 60, 0)
        } else if topSpace >= popoverSize.height + margin {
            y = anchor.minY - popoverSize.height - margin
        } else {
            y = min(textViewSize.height - popoverSize.height, anchor.maxY + margin)
        }

        y = max(0, min(y, textViewSize.height - popoverSize.height))

        return CGSize(width: clampedX, height: y)
    }

    private func synchronizeGlassFrame(with textSize: CGSize) {
        guard textSize != .zero else { return }

        let preferredSize = preferredGlassSize(for: textSize)
        glassSize = preferredSize

        if !isGlassInitialized {
            glassOrigin = initialGlassOrigin(for: textSize, blobSize: preferredSize)
            isGlassInitialized = true
        } else {
            glassOrigin = clampedOrigin(for: glassOrigin, in: textSize, blobSize: preferredSize)
        }
    }

    private func preferredGlassSize(for textSize: CGSize) -> CGSize {
        guard textSize != .zero else { return .zero }

        let maxWidth = textSize.width
        let width = min(max(maxWidth * 0.45, 140), maxWidth)
        let height = min(max(width * 0.6, 100), textSize.height)

        return CGSize(width: width, height: height)
    }

    private func initialGlassOrigin(for textSize: CGSize, blobSize: CGSize) -> CGPoint {
        let x = max((textSize.width - blobSize.width) / 2, 0)
        let targetY = textSize.height * 0.25 - blobSize.height / 2
        let y = max(0, min(targetY, max(0, textSize.height - blobSize.height)))

        return CGPoint(x: x, y: y)
    }

    private func clampedOrigin(for origin: CGPoint, in textSize: CGSize, blobSize: CGSize) -> CGPoint {
        let maxX = max(0, textSize.width - blobSize.width)
        let maxY = max(0, textSize.height - blobSize.height)

        let clampedX = min(max(origin.x, 0), maxX)
        let clampedY = min(max(origin.y, 0), maxY)

        return CGPoint(x: clampedX, y: clampedY)
    }
}

private struct LiquidGlassBlobView: View {
    let size: CGSize
    let isDragging: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityContrast) private var accessibilityContrast

    var body: some View {
        let cornerRadius = size.height * 0.45
        let emberOrange = Color(red: 0.98, green: 0.58, blue: 0.30)
        let emberDeep = Color(red: 0.78, green: 0.24, blue: 0.15)
        let emberGlow = Color(red: 1.0, green: 0.82, blue: 0.58)
        let outlineBase = colorScheme == .dark ? Color.white : Color.black
        let outlineOpacity = accessibilityContrast == .high ? 0.9 : 0.35
        let outlineWidth: CGFloat = accessibilityContrast == .high ? 3 : 1

        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                AngularGradient(
                    gradient: Gradient(colors: [emberGlow.opacity(0.65), emberOrange.opacity(0.75), emberDeep.opacity(0.6), emberGlow.opacity(0.65)]),
                    center: .center
                )
                .opacity(0.45)
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.35 : 0.55),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.screen)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(outlineBase.opacity(outlineOpacity), lineWidth: outlineWidth)
            )
            .shadow(color: emberOrange.opacity(isDragging ? 0.4 : 0.25), radius: isDragging ? 26 : 20, x: 0, y: isDragging ? 20 : 16)
            .shadow(color: Color.black.opacity(0.25), radius: isDragging ? 22 : 14, x: 0, y: 10)
            .frame(width: size.width, height: size.height)
            .overlay(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.75), Color.white.opacity(0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.width * 0.6, height: size.height * 0.32)
                    .offset(x: size.width * -0.12, y: size.height * -0.28)
                    .blur(radius: 6)
                    .blendMode(.screen)
            )
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.8), Color.white.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.45
                        )
                    )
                    .frame(width: size.width * 0.45, height: size.width * 0.45)
                    .offset(x: size.width * 0.28, y: size.height * 0.08)
                    .blendMode(.screen)
            )
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [emberOrange.opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.3
                        )
                    )
                    .frame(width: size.width * 0.3, height: size.width * 0.3)
                    .offset(x: size.width * -0.18, y: size.height * 0.45)
                    .blur(radius: 8)
                    .blendMode(.plusLighter)
            )
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [emberGlow.opacity(0.7), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.25
                        )
                    )
                    .frame(width: size.width * 0.2, height: size.width * 0.2)
                    .offset(x: size.width * 0.35, y: size.height * -0.12)
                    .blendMode(.screen)
            )
            .animation(.easeOut(duration: 0.2), value: isDragging)
    }
}

private struct WordTranslationPopover: View {
    let presentation: WordPopoverPresentation
    var onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(presentation.translation.headword)
                        .font(.headline)
                    Text(presentation.translation.vietnamese)
                        .font(.title3.weight(.semibold))
                }

                Spacer()

                Text(presentation.translation.partOfSpeech.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentColor.opacity(0.16))
                    )
            }

            if let definition = presentation.translation.englishDefinition,
               !definition.isEmpty {
                Text(definition)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !presentation.sampleSentence.isEmpty {
                Text("“\(presentation.sampleSentence)”")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onAdd) {
                Label("Add to Vocabulary", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
    }
}

private struct TextViewSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct PopoverSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct WordPopoverPresentation: Identifiable, Equatable {
    let id = UUID()
    let pageIndex: Int
    let selection: WordDetectingTextView.WordSelection
    let translation: WordTranslation
    let sampleSentence: String
    let anchorRect: CGRect

    init(pageIndex: Int, selection: WordDetectingTextView.WordSelection, translation: WordTranslation, sampleSentence: String) {
        self.pageIndex = pageIndex
        self.selection = selection
        self.translation = translation
        self.sampleSentence = sampleSentence

        if let firstRect = selection.boundingRects.first {
            anchorRect = selection.boundingRects.dropFirst().reduce(firstRect) { partialResult, rect in
                partialResult.union(rect)
            }
        } else {
            anchorRect = .zero
        }
    }

    static func == (lhs: WordPopoverPresentation, rhs: WordPopoverPresentation) -> Bool {
        lhs.id == rhs.id
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

