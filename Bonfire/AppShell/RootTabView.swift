import SwiftUI

struct RootTabView: View {
    @State private var selection: RootTab = .reader

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

private struct PlaceholderView: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(titleKey)
                .font(.title2.weight(.semibold))

            Text(LocalizedStringKey("placeholder.comingSoon"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

private enum RootTab: String, CaseIterable, Identifiable {
    case reader
    case audio
    case vocab
    case profile

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .reader:
            return LocalizedStringKey("tab.reader")
        case .audio:
            return LocalizedStringKey("tab.audio")
        case .vocab:
            return LocalizedStringKey("tab.vocab")
        case .profile:
            return LocalizedStringKey("tab.profile")
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .reader:
            ReaderHomeView()
        case .profile:
            ProfileView()
        case .audio, .vocab:
            PlaceholderView(titleKey: titleKey)
        }
    }

    var systemImage: String {
        switch self {
        case .reader:
            return "book"
        case .audio:
            return "headphones"
        case .vocab:
            return "text.book.closed"
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
