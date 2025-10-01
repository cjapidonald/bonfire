import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var userProfileStore: UserProfileStore
    @State private var selectedLanguage: AppLanguage = .english

    var body: some View {
        NavigationStack {
            Form {
                if let profile = userProfileStore.profile {
                    Section(header: Text(LocalizedStringKey("settings.section.account"))) {
                        LabeledContent(LocalizedStringKey("settings.account.parentName"), value: profile.displayName)
                    }
                }

                Section(header: Text(LocalizedStringKey("settings.section.language"))) {
                    Picker(LocalizedStringKey("settings.language"), selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.localizedNameKey)
                                .tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Developer")) {
                    NavigationLink("Developer Mode") {
                        DeveloperModeView()
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("settings.title"))
        }
        .onAppear {
            selectedLanguage = userProfileStore.profile?.interfaceLanguage ?? languageManager.currentLanguage
        }
        .onChange(of: selectedLanguage) { newValue in
            languageManager.setLanguage(newValue)
            userProfileStore.updateLanguage(newValue)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(LanguageManager())
            .environmentObject(UserProfileStore.preview)
    }
}
