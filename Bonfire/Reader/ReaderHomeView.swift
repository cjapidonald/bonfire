import Foundation
import SwiftUI

struct ReaderHomeView: View {
    @State private var path: [Book] = []
    @State private var levelFilter: LevelFilter = .all
    @State private var topicFilter: TopicFilter = .all
    @State private var lengthFilter: LengthFilter = .all
    @ObservedObject private var progressStore = ReaderProgressStore.shared

    private let contentProvider = ContentProvider.shared

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 24) {
                dashboardSection

                filterSection

                ScrollView {
                    VStack(spacing: 24) {
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
            }
            .padding(.top)
            .navigationTitle("Library")
            .navigationDestination(for: Book.self) { book in
                ReaderShellView(book: book)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    private var dashboardSection: some View {
        ReadingDashboardCard(
            minutesToday: max(0, progressStore.todaySummary.totalMinutes),
            starsToday: max(0, progressStore.todaySummary.starsEarned),
            bookProgress: currentBookSnapshot,
            streakCount: progressStore.currentStreakCount,
            weeklyActivity: weeklyActivityDays
        )
        .padding(.horizontal)
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

    private var currentBookSnapshot: BookProgressSnapshot? {
        guard let progress = progressStore.mostRecentBookProgress else { return nil }
        guard let book = contentProvider.books.first(where: { $0.id == progress.bookID }) else { return nil }
        guard !book.pages.isEmpty else { return nil }

        let pageIndices = Set(book.pages.map { $0.index })
        let visitedCount = progress.visitedPageIndices.intersection(pageIndices).count
        let percent = Int((Double(visitedCount) / Double(book.pages.count) * 100).rounded())

        return BookProgressSnapshot(title: book.title, percentComplete: percent)
    }

    private var weeklyActivityDays: [WeeklyActivityDay] {
        progressStore.weeklySummaries().map { summary in
            WeeklyActivityDay(date: summary.date, hasActivity: summary.hasActivity)
        }
    }
}

private struct BookProgressSnapshot {
    let title: String
    let percentComplete: Int
}

private struct WeeklyActivityDay: Identifiable {
    let date: Date
    let hasActivity: Bool

    var id: Date { date }
}

private struct ReadingDashboardCard: View {
    let minutesToday: Int
    let starsToday: Int
    let bookProgress: BookProgressSnapshot?
    let streakCount: Int
    let weeklyActivity: [WeeklyActivityDay]

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter
    }()

    private var accessibilitySummary: String {
        var components: [String] = ["Today's progress."]
        components.append("\(minutesToday) minutes read today.")
        components.append("\(starsToday) stars earned today.")

        if let bookProgress {
            components.append("Current book \(bookProgress.title), \(bookProgress.percentComplete) percent complete.")
        } else {
            components.append("No current book progress yet.")
        }

        components.append("Weekly streak \(streakCount) \(streakCount == 1 ? "day" : "days").")
        return components.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Today's Progress")
                .font(.headline)

            HStack(spacing: 16) {
                DashboardMetricView(
                    value: "\(minutesToday)",
                    unit: "min",
                    unitColor: .secondary,
                    label: "Minutes today"
                )

                DashboardMetricView(
                    value: "\(starsToday)",
                    unit: "★",
                    unitColor: Color.yellow.opacity(0.85),
                    label: "Stars earned"
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                currentBookView
                streakView
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
    }

    private var currentBookView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current book")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            if let bookProgress {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(bookProgress.percentComplete)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    Text("%")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(bookProgress.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("Overall completion")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("--")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text("%")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text("Start reading to track progress")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var streakView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly streak")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(streakCount)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(streakCount == 1 ? "day" : "days")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("🔥")
                    .font(.title3)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Weekly streak"))
            .accessibilityValue(Text("\(streakCount) day streak"))

            if weeklyActivity.isEmpty {
                Text("No reading yet this week")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 12) {
                    ForEach(weeklyActivity) { day in
                        VStack(spacing: 6) {
                            Text(dayAbbreviation(for: day.date))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Circle()
                                .fill(day.hasActivity ? Color.accentColor : Color.gray.opacity(0.2))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            Color.accentColor,
                                            lineWidth: Calendar.current.isDateInToday(day.date) ? 2 : 0
                                        )
                                )
                                .accessibilityLabel(Text(accessibilityLabel(for: day)))
                        }
                    }
                }
            }
        }
    }

    private func dayAbbreviation(for date: Date) -> String {
        let formatted = Self.dayFormatter.string(from: date)
        return String(formatted.prefix(1)).uppercased()
    }

    private func accessibilityLabel(for day: WeeklyActivityDay) -> String {
        let calendar = Calendar.current
        let dayName = Self.dayFormatter.string(from: day.date)

        if calendar.isDateInToday(day.date) {
            return day.hasActivity ? "Today: streak active" : "Today: no reading yet"
        }

        return day.hasActivity ? "\(dayName): streak active" : "\(dayName): no reading"
    }
}

private struct DashboardMetricView: View {
    let value: String
    let unit: String?
    let unitColor: Color
    let label: String

    init(value: String, unit: String? = nil, unitColor: Color = .secondary, label: String) {
        self.value = value
        self.unit = unit
        self.unitColor = unitColor
        self.label = label
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()

                if let unit {
                    Text(unit)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(unitColor)
                }
            }

            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Card View

private struct BookCardView: View {
    let book: Book

    private var accessibilityLabelText: String {
        let tagSummary = book.tags.joined(separator: ", ")
        guard !tagSummary.isEmpty else { return book.title }
        return "\(book.title). \(tagSummary)."
    }

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabelText))
        .accessibilityHint(Text(String(localized: "reader.bookCard.hint")))
        .accessibilityAddTraits(.isButton)
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
        .accessibilityHidden(true)
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
    @StateObject private var audioController: ReaderAudioController
    @State private var selectedPageIndex: Int
    @State private var isLiquidGlassEnabled: Bool = false
    @State private var lastWordInteractionDescription: String?
    @ObservedObject private var vocabularyStore = VocabularyStore.shared
    @ObservedObject private var progressStore = ReaderProgressStore.shared
    @State private var activePopover: WordPopoverPresentation?
    @State private var totalWordsCounted: Int = 0
    @State private var pageUniqueWordSets: [Int: Set<String>] = [:]
    @State private var lastCountTimestamps: [String: Date] = [:]
    @State private var sessionFeedback: SessionFeedback?
    @State private var isSubmitting: Bool = false
    @State private var hasObservedInitialLevel: Bool = false
    @State private var lastDifficultyChange: Date?
    @State private var lastSubmittedSessionID: UUID?
    @State private var observedSessionID: UUID?

    private let translationProvider = WordTranslationProvider.shared
    private let sessionValidator = SessionValidator()

    init(book: Book) {
        self.book = book
        _readerState = StateObject(wrappedValue: ReaderState(book: book))
        _audioController = StateObject(wrappedValue: ReaderAudioController(book: book))
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
        .onReceive(readerState.$level) { _ in
            if hasObservedInitialLevel {
                lastDifficultyChange = Date()
            } else {
                hasObservedInitialLevel = true
            }
        }
        .onReceive(audioController.$latestSession) { session in
            if let session {
                if observedSessionID != session.id {
                    observedSessionID = session.id
                    lastSubmittedSessionID = nil
                }
            } else {
                observedSessionID = nil
                lastSubmittedSessionID = nil
            }
        }
        .alert(item: $sessionFeedback) { feedback in
            Alert(
                title: Text(feedback.title),
                message: Text(feedback.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(book.title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

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
                    onWordCounted: { selection in
                        handleWordCounted(on: page.index, selection: selection)
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
        VStack(spacing: 16) {
            Divider()

            ReaderAudioControls(controller: audioController)
                .padding(.horizontal)

            if isLiquidGlassEnabled {
                LiquidGlassSessionSummary(
                    totalCount: totalWordsCounted,
                    uniqueCount: uniqueWordsOnCurrentPageCount
                )
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(spacing: 12) {
                LiquidGlassToggle(isOn: $isLiquidGlassEnabled)

                Spacer()

                Button(action: submitSession) {
                    Text("Submit Reading")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSubmitSession)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
        .animation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2), value: isLiquidGlassEnabled)
    }

    private var currentPagePosition: Int {
        guard let index = book.pages.firstIndex(where: { $0.index == selectedPageIndex }) else {
            return 1
        }
        return index + 1
    }

    private var canSubmitSession: Bool {
        guard !isSubmitting else { return false }
        guard audioController.state == .idle else { return false }
        guard let session = audioController.latestSession else { return false }
        guard totalWordsCounted > 0 else { return false }
        if let submittedID = lastSubmittedSessionID, submittedID == session.id {
            return false
        }
        return true
    }

    private var readingProgress: Double {
        guard !book.pages.isEmpty else { return 0 }
        let progress = progressStore.progress(for: book)
        let visitedCount = progress.visitedPageIndices.intersection(book.pages.map { $0.index }).count
        return Double(visitedCount) / Double(book.pages.count)
    }

    private var uniqueWordsOnCurrentPageCount: Int {
        pageUniqueWordSets[selectedPageIndex]?.count ?? 0
    }

    private func submitSession() {
        guard canSubmitSession, let session = audioController.latestSession else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        let input = SessionValidator.Input(
            totalWords: totalWordsCounted,
            duration: session.duration,
            sessionEndedAt: session.createdAt,
            lastDifficultyChange: lastDifficultyChange
        )
        let result = sessionValidator.validate(input)

        var metadata: [String: String] = [
            "book_id": book.id.uuidString,
            "level": readerState.level.rawValue,
            "words_counted": String(totalWordsCounted),
            "duration_seconds": String(format: "%.2f", session.duration),
            "wpm": String(format: "%.1f", result.wordsPerMinute),
            "session_id": session.id.uuidString
        ]

        switch result.status {
        case .accepted:
            let uniqueWordCounts = pageUniqueWordSets.mapValues { $0.count }
            let reward = progressStore.recordSession(
                for: book,
                level: readerState.level,
                totalWordsCounted: totalWordsCounted,
                uniqueWordCounts: uniqueWordCounts,
                recording: session,
                qualityFactor: result.qualityFactor,
                lastViewedPageIndex: selectedPageIndex
            )

            lastSubmittedSessionID = session.id
            activePopover = nil

            let summary = progressSummaryText(for: reward.updatedProgress)
            sessionFeedback = SessionFeedback.success(stars: reward.starsAwarded, summary: summary)
            if let message = sessionFeedback?.message {
                lastWordInteractionDescription = "⭐️ \(message)"
            }

            metadata["stars_awarded"] = String(reward.starsAwarded)
            metadata["quality_factor"] = String(format: "%.2f", result.qualityFactor)
            metadata["new_pages"] = String(reward.newlyVisitedPageIndices.count)
            metadata["pages_visited_total"] = String(reward.updatedProgress.visitedPageIndices.count)
            metadata["status"] = "accepted"

            AnalyticsLogger.shared.log(event: "session_submitted", metadata: metadata)

            resetSessionTracking()
        case .rejected(let reason):
            let message = result.helpfulTip ?? "This reading session didn't meet the requirements to award stars."
            sessionFeedback = SessionFeedback.failure(message: message)
            lastWordInteractionDescription = message

            metadata["status"] = "rejected"
            let failureDetails = failureMetadata(for: reason)
            for (key, value) in failureDetails {
                metadata[key] = value
            }

            AnalyticsLogger.shared.log(event: "session_submitted", metadata: metadata)

            var invalidMetadata = failureDetails
            invalidMetadata["book_id"] = book.id.uuidString
            invalidMetadata["session_id"] = session.id.uuidString
            invalidMetadata["level"] = readerState.level.rawValue
            invalidMetadata["words_counted"] = String(totalWordsCounted)
            invalidMetadata["duration_seconds"] = String(format: "%.2f", session.duration)
            invalidMetadata["wpm"] = String(format: "%.1f", result.wordsPerMinute)

            AnalyticsLogger.shared.log(event: "session_invalid_reason", metadata: invalidMetadata)
        }
    }

    private func resetSessionTracking() {
        totalWordsCounted = 0
        pageUniqueWordSets = [:]
        lastCountTimestamps = [:]
    }

    private func progressSummaryText(for progress: BookProgress) -> String {
        let visited = progress.visitedPageIndices.count
        let total = book.pages.count
        return "Progress: \(visited)/\(total) pages complete."
    }

    private func failureMetadata(for reason: SessionValidator.Result.FailureReason) -> [String: String] {
        switch reason {
        case .noWords:
            return ["reason": "no_words"]
        case .zeroDuration:
            return ["reason": "zero_duration"]
        case .paceOutOfRange(let wordsPerMinute):
            return [
                "reason": "pace_out_of_range",
                "observed_wpm": String(format: "%.1f", wordsPerMinute)
            ]
        case .belowMinimumDuration(let required):
            return [
                "reason": "below_minimum_duration",
                "required_seconds": String(format: "%.2f", required)
            ]
        }
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
        AnalyticsLogger.shared.log(
            event: "word_tapped",
            metadata: [
                "book_id": book.id.uuidString,
                "page_index": String(page.index),
                "term": selection.normalized,
                "surface": selection.original,
                "source": "single"
            ]
        )

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
        AnalyticsLogger.shared.log(
            event: "word_tapped",
            metadata: [
                "book_id": book.id.uuidString,
                "page_index": String(page.index),
                "term": selection.normalized,
                "surface": selection.original,
                "source": "double"
            ]
        )

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

    private func handleWordCounted(on pageIndex: Int, selection: WordDetectingTextView.WordSelection) -> Bool {
        guard isLiquidGlassEnabled else { return false }
        guard pageIndex == selectedPageIndex else { return false }

        let normalizedKey = selection.normalized.lowercased()
        let now = Date()

        if let last = lastCountTimestamps[normalizedKey], now.timeIntervalSince(last) < 3 {
            return false
        }

        lastCountTimestamps[normalizedKey] = now
        totalWordsCounted += 1

        var uniqueSet = pageUniqueWordSets[pageIndex] ?? []
        uniqueSet.insert(normalizedKey)
        pageUniqueWordSets[pageIndex] = uniqueSet

        lastWordInteractionDescription = "✨ Counted “\(selection.original)” • Words: \(totalWordsCounted) • Unique this page: \(uniqueSet.count)"

        AnalyticsLogger.shared.log(
            event: "lg_word_counted",
            metadata: [
                "book_id": book.id.uuidString,
                "page_index": String(pageIndex),
                "term": selection.normalized,
                "surface": selection.original,
                "total_words": String(totalWordsCounted),
                "unique_words_on_page": String(uniqueSet.count)
            ]
        )

        return true
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
            event: "word_added_vocab",
            metadata: [
                "term": entry.normalized,
                "book_id": book.id.uuidString,
                "page_index": String(presentation.pageIndex),
                "source": source,
                "surface": entry.original
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
                    let option = levels[index]

                    Button {
                        select(option)
                    } label: {
                        tick(isActive: index == activeIndex)
                            .accessibilityHidden(true)
                    }
                    .buttonStyle(.plain)
                    .offset(y: step * CGFloat(index))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(accessibilityLabel(for: option)))
                    .accessibilityHint(Text(accessibilityHint(for: index)))
                    .accessibilityValue(Text(accessibilityValue(for: index)))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAddTraits(index == activeIndex ? .isSelected : [])
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
                .accessibilityHint(Text(accessibilityHint(for: index)))
                .accessibilityAddTraits(.isButton)
                .accessibilityAddTraits(index == activeIndex ? .isSelected : [])

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
        .accessibilityHidden(true)
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

    private func accessibilityLabel(for level: Level) -> String {
        String(format: String(localized: "reader.gear.label"), level.rawValue)
    }

    private func accessibilityHint(for index: Int) -> String {
        index == activeIndex
            ? String(localized: "reader.gear.hint.selected")
            : String(localized: "reader.gear.hint.choose")
    }

    private func accessibilityValue(for index: Int) -> String {
        index == activeIndex
            ? String(localized: "reader.gear.value.selected")
            : String(localized: "reader.gear.value.notSelected")
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
    var onWordCounted: (WordDetectingTextView.WordSelection) -> Bool = { _ in false }
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
                        onAddToVocabulary: onAddToVocabulary,
                        onWordCounted: onWordCounted
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
    var onWordCounted: (WordDetectingTextView.WordSelection) -> Bool

    @State private var textViewSize: CGSize = .zero
    @State private var popoverSize: CGSize = .zero
    @State private var glassOrigin: CGPoint = .zero
    @State private var glassSize: CGSize = .zero
    @State private var isGlassInitialized: Bool = false
    @State private var isDraggingGlass: Bool = false
    @State private var dragStartToken: WordDetectingTextView.WordToken?
    @State private var dragStartCenter: CGPoint?
    @State private var wordTokens: [WordDetectingTextView.WordToken] = []
    @State private var currentToken: WordDetectingTextView.WordToken?
    @State private var dwellTask: Task<Void, Never>?
    @State private var activeStarburstID: UUID?

    private let horizontalPadding: CGFloat = 18
    private let verticalPadding: CGFloat = 12
    private let minimumGlassHeight: CGFloat = 80
    private let minimumGlassWidth: CGFloat = 96

    var body: some View {
        ScrollView {
            WordDetectingTextView(
                text: text,
                onSingleTap: onSingleTap,
                onDoubleTap: onDoubleTap,
                onTokensUpdate: handleTokensUpdate
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
                        ZStack {
                            LiquidGlassBlobView(size: glassSize, isDragging: isDraggingGlass)
                                .accessibilityHidden(true)

                            if let starburstID = activeStarburstID {
                                StarburstView(triggerID: starburstID)
                                    .frame(width: glassSize.width * 1.15, height: glassSize.height * 1.15)
                                    .allowsHitTesting(false)
                                    .transition(.opacity)
                            }
                        }
                        .offset(x: glassOrigin.x, y: glassOrigin.y)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard isLiquidGlassEnabled else { return }

                                    if !isDraggingGlass {
                                        isDraggingGlass = true
                                        dragStartToken = currentToken ?? wordTokens.first
                                        dragStartCenter = dragStartToken?.frame.center ?? CGPoint(x: glassOrigin.x + glassSize.width / 2, y: glassOrigin.y + glassSize.height / 2)
                                    }

                                    guard let startToken = dragStartToken else { return }
                                    let startCenter = dragStartCenter ?? startToken.frame.center

                                    var proposedPoint = CGPoint(
                                        x: startCenter.x + value.translation.width,
                                        y: startCenter.y + value.translation.height
                                    )

                                    proposedPoint.x = max(0, min(proposedPoint.x, textViewSize.width))
                                    proposedPoint.y = max(0, min(proposedPoint.y, textViewSize.height))

                                    if let target = token(near: proposedPoint) {
                                        snap(to: target, reason: .userInteraction, animated: false)
                                    }
                                }
                                .onEnded { _ in
                                    isDraggingGlass = false
                                    dragStartToken = nil
                                    dragStartCenter = nil
                                }
                        )
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
            synchronizeGlassFrame(with: wordTokens, containerSize: newSize)
        }
        .onChange(of: isLiquidGlassEnabled) { isEnabled in
            if isEnabled {
                synchronizeGlassFrame(with: wordTokens, containerSize: textViewSize, animate: true)
            } else {
                isDraggingGlass = false
                cancelDwellTask()
                activeStarburstID = nil
            }
        }
        .onAppear {
            synchronizeGlassFrame(with: wordTokens, containerSize: textViewSize)
        }
        .onDisappear { cancelDwellTask() }
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

    private func clampedOrigin(for origin: CGPoint, in textSize: CGSize, blobSize: CGSize) -> CGPoint {
        let maxX = max(0, textSize.width - blobSize.width)
        let maxY = max(0, textSize.height - blobSize.height)

        let clampedX = min(max(origin.x, 0), maxX)
        let clampedY = min(max(origin.y, 0), maxY)

        return CGPoint(x: clampedX, y: clampedY)
    }

    private func handleTokensUpdate(_ tokens: [WordDetectingTextView.WordToken]) {
        wordTokens = tokens.filter { !$0.frame.isEmpty }
        synchronizeGlassFrame(with: wordTokens, containerSize: textViewSize)
    }

    private func synchronizeGlassFrame(
        with tokens: [WordDetectingTextView.WordToken],
        containerSize: CGSize,
        animate: Bool = false
    ) {
        guard containerSize != .zero else { return }

        if let current = currentToken,
           let updated = tokens.first(where: { $0.id == current.id }) {
            snap(to: updated, reason: .layoutSync, animated: animate)
        } else if isLiquidGlassEnabled, let first = tokens.first {
            snap(to: first, reason: isGlassInitialized ? .layoutSync : .initialization, animated: animate)
        } else if tokens.isEmpty {
            glassSize = .zero
            glassOrigin = .zero
            currentToken = nil
            isGlassInitialized = false
        }
    }

    private enum SnapReason {
        case initialization
        case layoutSync
        case userInteraction
    }

    private func snap(
        to token: WordDetectingTextView.WordToken,
        reason: SnapReason,
        animated: Bool
    ) {
        guard textViewSize != .zero else { return }
        guard !token.frame.isEmpty else { return }

        let paddedFrame = token.frame.insetBy(dx: -horizontalPadding, dy: -verticalPadding)
        var targetWidth = max(paddedFrame.width, token.frame.width + horizontalPadding * 2)
        var targetHeight = max(paddedFrame.height, token.frame.height + verticalPadding * 2)

        targetWidth = min(max(targetWidth, minimumGlassWidth), textViewSize.width)
        targetHeight = min(max(targetHeight, minimumGlassHeight), textViewSize.height)

        let rawOrigin = CGPoint(
            x: paddedFrame.origin.x,
            y: token.frame.midY - targetHeight / 2
        )

        let adjustedOrigin = clampedOrigin(
            for: rawOrigin,
            in: textViewSize,
            blobSize: CGSize(width: targetWidth, height: targetHeight)
        )

        let previousID = currentToken?.id
        let updateState = {
            glassSize = CGSize(width: targetWidth, height: targetHeight)
            glassOrigin = adjustedOrigin
            currentToken = token
            isGlassInitialized = true
        }

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.2)) {
                updateState()
            }
        } else {
            updateState()
        }

        if reason == .userInteraction, previousID != token.id {
            scheduleDwell(for: token)
        }
    }

    private func scheduleDwell(for token: WordDetectingTextView.WordToken) {
        dwellTask?.cancel()

        dwellTask = Task { [selection = token.selection, tokenID = token.id] in
            try await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard isLiquidGlassEnabled else { return }
                guard currentToken?.id == tokenID else { return }

                if onWordCounted(selection) {
                    triggerStarburst()
                }
            }
        }
    }

    private func cancelDwellTask() {
        dwellTask?.cancel()
        dwellTask = nil
    }

    private func token(near point: CGPoint) -> WordDetectingTextView.WordToken? {
        let tokens = wordTokens.filter { !$0.frame.isEmpty }
        guard !tokens.isEmpty else { return nil }

        let verticalTolerance: CGFloat = 10
        let containing = tokens.filter {
            $0.frame.insetBy(dx: 0, dy: -verticalTolerance).contains(point)
        }

        if let match = containing.min(by: { abs($0.frame.midX - point.x) < abs($1.frame.midX - point.x) }) {
            return match
        }

        let sameLine = tokens.filter {
            abs($0.frame.midY - point.y) <= ($0.frame.height / 2 + verticalTolerance)
        }

        if let match = sameLine.min(by: { abs($0.frame.midX - point.x) < abs($1.frame.midX - point.x) }) {
            return match
        }

        return tokens.min { lhs, rhs in
            distanceSquared(lhs.frame.center, point) < distanceSquared(rhs.frame.center, point)
        }
    }

    private func triggerStarburst() {
        let newID = UUID()
        withAnimation(.easeOut(duration: 0.2)) {
            activeStarburstID = newID
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            if activeStarburstID == newID {
                withAnimation(.easeOut(duration: 0.2)) {
                    activeStarburstID = nil
                }
            }
        }
    }

    private func distanceSquared(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
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

private struct StarburstView: View {
    let triggerID: UUID

    @State private var animate: Bool = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                let angle = Double(index) / 6.0 * (.pi * 2)
                let radius: CGFloat = index.isMultiple(of: 2) ? 28 : 20
                let symbolSize: CGFloat = index.isMultiple(of: 2) ? 18 : 14

                Image(systemName: "sparkle")
                    .font(.system(size: symbolSize, weight: .semibold))
                    .foregroundStyle(Color.yellow.opacity(0.85))
                    .scaleEffect(animate ? 1 : 0.4)
                    .opacity(animate ? 0 : 1)
                    .offset(
                        x: animate ? CGFloat(cos(angle)) * radius : 0,
                        y: animate ? CGFloat(sin(angle)) * radius : 0
                    )
                    .blendMode(.plusLighter)
                    .animation(.easeOut(duration: 0.55), value: animate)
            }

            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundStyle(Color.yellow.opacity(0.75))
                .scaleEffect(animate ? 1.35 : 1)
                .opacity(animate ? 0 : 0.85)
                .blendMode(.plusLighter)
                .animation(.easeOut(duration: 0.5), value: animate)
        }
        .id(triggerID)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animate = true
            }
        }
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
            .accessibilityHint(Text(String(localized: "reader.word.saveHint")))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
    }
}

private struct SessionFeedback: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    static func success(stars: Int, summary: String) -> SessionFeedback {
        let starText = stars == 1 ? "1 star" : "\(stars) stars"
        return SessionFeedback(
            title: "Great Job!",
            message: "You earned \(starText) this session. \(summary)"
        )
    }

    static func failure(message: String) -> SessionFeedback {
        SessionFeedback(title: "Session Not Counted", message: message)
    }
}

private struct LiquidGlassSessionSummary: View {
    let totalCount: Int
    let uniqueCount: Int

    var body: some View {
        HStack(spacing: 20) {
            metric(symbol: "sparkle", title: "Words Counted", value: totalCount)

            Divider()
                .frame(width: 1, height: 32)
                .background(Color.primary.opacity(0.08))

            metric(symbol: "text.book.closed", title: "Unique on Page", value: uniqueCount)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.accentColor.opacity(0.08))
        )
    }

    private func metric(symbol: String, title: String, value: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(value)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
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

private struct ReaderAudioControls: View {
    @ObservedObject var controller: ReaderAudioController

    private var isRecording: Bool { controller.state == .recording }
    private var isPlaying: Bool { controller.state == .playing }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    controller.startRecording()
                } label: {
                    Label(isRecording ? "Recording" : "Record", systemImage: isRecording ? "record.circle.fill" : "record.circle")
                        .font(.title3.weight(.semibold))
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.red)
                .disabled(isRecording || isPlaying)
                .accessibilityHint(Text("Starts a new recording"))

                Button {
                    controller.stop()
                } label: {
                    Label("Stop", systemImage: "stop.circle")
                        .font(.title3.weight(.semibold))
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.orange)
                .disabled(!isRecording && !isPlaying)
                .accessibilityHint(Text("Stops the current recording or playback"))

                Button {
                    controller.togglePlayback()
                } label: {
                    Label(isPlaying ? "Listening" : "Listen", systemImage: isPlaying ? "pause.circle" : "play.circle")
                        .font(.title3.weight(.semibold))
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.blue)
                .disabled(controller.latestSession == nil || isRecording)
                .accessibilityHint(Text("Replays the most recent recording"))
            }

            VStack(alignment: .leading, spacing: 12) {
                AudioMeterView(level: controller.meterLevel, state: controller.state)
                    .frame(height: 26)

                HStack(alignment: .center, spacing: 12) {
                    let total = isRecording ? controller.elapsedTime : controller.duration
                    Text("\(controller.formattedTime(controller.elapsedTime)) / \(controller.formattedTime(total))")
                        .font(.title2.monospacedDigit())
                        .fontWeight(.bold)
                        .accessibilityLabel(Text("Elapsed time"))
                        .accessibilityValue(Text("\(controller.formattedTime(controller.elapsedTime)) of \(controller.formattedTime(total))"))

                    Spacer()

                    Picker("Playback Speed", selection: Binding(
                        get: { controller.playbackSpeed },
                        set: { controller.setPlaybackSpeed($0) }
                    )) {
                        ForEach(ReaderAudioController.PlaybackSpeed.allCases) { speed in
                            Text(speed.label).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                    .frame(maxWidth: 260)
                    .accessibilityLabel(Text("Playback speed"))
                    .disabled(controller.latestSession == nil && !isPlaying)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct AudioMeterView: View {
    let level: Float
    let state: ReaderAudioController.State

    private var fillColor: Color {
        switch state {
        case .recording:
            return .red
        case .playing:
            return .blue
        case .idle:
            return Color.accentColor
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let normalized = max(0, min(level, 1))
            let width = normalized == 0 ? 0 : geometry.size.width * CGFloat(max(normalized, 0.08))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))

                Capsule()
                    .fill(fillColor.opacity(0.85))
                    .frame(width: width)
                    .animation(.easeOut(duration: 0.15), value: normalized)
            }
        }
        .accessibilityLabel(Text("Audio level"))
        .accessibilityValue(Text("\(Int(level * 100)) percent"))
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
        .accessibilityHint(Text(String(localized: "reader.toggle.liquidGlassHint")))
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

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

#if DEBUG
struct ReaderHomeView_Previews: PreviewProvider {
    static var previews: some View {
        ReaderHomeView()
    }
}
#endif

