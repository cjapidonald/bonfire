import Foundation
import SwiftUI

struct UserProfile: Codable, Equatable {
    let id: String
    var displayName: String
    var avatarIdentifier: String
    var interfaceLanguage: AppLanguage
}

@MainActor
final class UserProfileStore: ObservableObject {
    @Published private(set) var profile: UserProfile?

    private let userDefaults: UserDefaults
    private let storageKey = "user.profile.record"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard, initialProfile: UserProfile? = nil) {
        self.userDefaults = userDefaults

        if let initialProfile {
            profile = initialProfile
        } else if
            let data = userDefaults.data(forKey: storageKey),
            let decoded = try? decoder.decode(UserProfile.self, from: data)
        {
            profile = decoded
        } else {
            profile = nil
        }
    }

    var isSignedIn: Bool {
        profile != nil
    }

    func saveProfile(_ profile: UserProfile) {
        guard let data = try? encoder.encode(profile) else { return }
        userDefaults.set(data, forKey: storageKey)
        self.profile = profile
    }

    func saveProfile(id: String, displayName: String, avatarIdentifier: String, language: AppLanguage) {
        let profile = UserProfile(
            id: id,
            displayName: displayName,
            avatarIdentifier: avatarIdentifier,
            interfaceLanguage: language
        )
        saveProfile(profile)
    }

    func updateLanguage(_ language: AppLanguage) {
        guard var existingProfile = profile else { return }
        existingProfile.interfaceLanguage = language
        saveProfile(existingProfile)
    }
}

extension UserProfileStore {
    static var preview: UserProfileStore {
        UserProfileStore(
            userDefaults: UserDefaults(suiteName: "preview.user.profile") ?? .standard,
            initialProfile: UserProfile(
                id: "preview",
                displayName: "Taylor Parent",
                avatarIdentifier: "default-parent",
                interfaceLanguage: .english
            )
        )
    }
}
