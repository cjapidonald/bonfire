import SwiftUI

@main
struct BonfireApp: App {
    @StateObject private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.locale)
        }
    }
}
