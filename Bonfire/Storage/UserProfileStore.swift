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
    private let privateSync = PrivateSyncCoordinator.shared

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
        enqueuePrivateSync(for: profile)
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

    private func enqueuePrivateSync(for profile: UserProfile) {
        let readerStore = ReaderProgressStore.shared
        let streak = readerStore.currentStreakCount
        let lastSessionAt = readerStore.mostRecentBookProgress?.lastReadAt
        let snapshot = UserProfileSnapshot(
            recordName: profile.id,
            displayName: profile.displayName,
            preferredLocale: profile.interfaceLanguage.localeIdentifier,
            readingStreak: streak,
            lastSessionAt: lastSessionAt,
            modifiedAt: Date()
        )

        Task(priority: .utility) { [snapshot] in
            await privateSync.upsertUserProfile(snapshot)
        }
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
