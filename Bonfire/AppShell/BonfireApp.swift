import SwiftUI

@main
struct BonfireApp: App {
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var userProfileStore = UserProfileStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if userProfileStore.isSignedIn {
                    RootTabView()
                } else {
                    OnboardingSignInView()
                }
            }
            .environmentObject(languageManager)
            .environmentObject(userProfileStore)
            .environment(\.locale, languageManager.locale)
        }
    }
}
