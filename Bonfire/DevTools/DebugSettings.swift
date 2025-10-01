#if DEBUG
import Combine
import Foundation

@MainActor
final class DebugSettings: ObservableObject {
    static let shared = DebugSettings()

    @Published var isMenuPresented: Bool = false
    @Published var isOffline: Bool = false {
        didSet {
            applyConnectivityState()
        }
    }

    private let performanceSettings = PerformanceSettings.shared
    private let progressStore = ReaderProgressStore.shared
    private let vocabularyStore = VocabularyStore.shared
    private let recordingStore = ReaderRecordingStore.shared

    private init() {}

    func toggleMenu() {
        isMenuPresented.toggle()
    }

    func resetAppData() {
        progressStore.debugReset()
        vocabularyStore.debugReset()
        recordingStore.debugReset()
        performanceSettings.resetVisualEffects()
    }

    func seedVocabulary() {
        vocabularyStore.debugSeedEntries()
    }

    func grantBadges() {
        progressStore.debugSeedProgress()
        recordingStore.debugSeedSessions()
        vocabularyStore.debugEnsureMinimumEntries(count: 20)
        progressStore.debugBoostStarCount()
    }

    func setParticlesEnabled(_ isEnabled: Bool) {
        performanceSettings.setParticlesEnabled(isEnabled)
    }

    func setBlurEnabled(_ isEnabled: Bool) {
        performanceSettings.setBlurEnabled(isEnabled)
    }

    private func applyConnectivityState() {
        let online = !isOffline
        Task {
            await PrivateSyncCoordinator.shared.updateConnectivity(isOnline: online)
        }
    }
}
#endif
