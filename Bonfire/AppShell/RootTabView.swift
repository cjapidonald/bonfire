import SwiftUI

struct RootTabView: View {
    @State private var selection: RootTab = .books

    var body: some View {
        TabView(selection: $selection) {
            ForEach(RootTab.allCases) { tab in
                tab.destination
                    .tabItem {
                        Label(tab.titleKey, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
    }
}

private enum RootTab: String, CaseIterable, Identifiable {
    case books
    case vocab
    case achievements
    case profile

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .books:
            return LocalizedStringKey("tab.books")
        case .vocab:
            return LocalizedStringKey("tab.vocabulary")
        case .achievements:
            return LocalizedStringKey("tab.achievements")
        case .profile:
            return LocalizedStringKey("tab.profile")
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .books:
            BooksTabView()
        case .vocab:
            VocabularyTabView()
        case .achievements:
            AchievementsTabView()
        case .profile:
            ProfileView()
        }
    }

    var systemImage: String {
        switch self {
        case .books:
            return "book"
        case .vocab:
            return "text.book.closed"
        case .achievements:
            return "trophy"
        case .profile:
            return "person"
        }
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .environmentObject(LanguageManager())
    }
}
