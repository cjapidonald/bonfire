import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var selectedLanguage: AppLanguage = .english

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("settings.section.language"))) {
                    Picker(LocalizedStringKey("settings.language"), selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.localizedNameKey)
                                .tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(LocalizedStringKey("settings.title"))
        }
        .onAppear {
            selectedLanguage = languageManager.currentLanguage
        }
        .onChange(of: selectedLanguage) { newValue in
            languageManager.setLanguage(newValue)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(LanguageManager())
    }
}
