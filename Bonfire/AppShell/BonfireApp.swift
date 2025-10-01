import SwiftUI

@main
struct BonfireApp: App {
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var userProfileStore = UserProfileStore()
    @StateObject private var performanceSettings = PerformanceSettings.shared
#if DEBUG
    @StateObject private var debugSettings = DebugSettings.shared
#endif

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
            .environmentObject(performanceSettings)
#if DEBUG
            .environmentObject(debugSettings)
            .overlay(alignment: .topTrailing) {
                DebugMenuButton()
                    .padding()
            }
            .sheet(isPresented: $debugSettings.isMenuPresented) {
                DebugMenuView()
            }
#endif
        }
    }
}
