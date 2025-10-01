import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case vietnamese = "vi"

    var id: String { rawValue }

    var localeIdentifier: String { rawValue }

    var localizedNameKey: LocalizedStringKey {
        switch self {
        case .english:
            return LocalizedStringKey("language.english")
        case .vietnamese:
            return LocalizedStringKey("language.vietnamese")
        }
    }
}

final class LanguageManager: ObservableObject {
    @Published private(set) var currentLanguage: AppLanguage
    @Published private(set) var locale: Locale

    private let userDefaults: UserDefaults
    private let storageKey = "app.selectedLanguage"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if
            let identifier = userDefaults.string(forKey: storageKey),
            let savedLanguage = AppLanguage(rawValue: identifier)
        {
            currentLanguage = savedLanguage
        } else {
            currentLanguage = .english
        }

        locale = Locale(identifier: currentLanguage.localeIdentifier)
    }

    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }

        currentLanguage = language
        locale = Locale(identifier: language.localeIdentifier)
        userDefaults.set(language.rawValue, forKey: storageKey)
    }
}
