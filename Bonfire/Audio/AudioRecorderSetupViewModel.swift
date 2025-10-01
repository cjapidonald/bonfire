import AVFoundation
import Foundation
import SwiftUI
import UIKit

@MainActor
final class AudioRecorderSetupViewModel: ObservableObject {
    enum PermissionStatus {
        case notDetermined
        case denied
        case granted

        init(recordPermission: AVAudioSession.RecordPermission) {
            switch recordPermission {
            case .undetermined:
                self = .notDetermined
            case .denied:
                self = .denied
            case .granted:
                self = .granted
            @unknown default:
                self = .denied
            }
        }
    }

    enum RecordingState: String, CaseIterable, Identifiable {
        case idle
        case recording
        case paused
        case playing

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .idle:
                return "moon.zzz"
            case .recording:
                return "record.circle"
            case .paused:
                return "pause.circle"
            case .playing:
                return "play.circle"
            }
        }

        var localizedKey: LocalizedStringKey {
            switch self {
            case .idle:
                return LocalizedStringKey("audio.state.idle")
            case .recording:
                return LocalizedStringKey("audio.state.recording")
            case .paused:
                return LocalizedStringKey("audio.state.paused")
            case .playing:
                return LocalizedStringKey("audio.state.playing")
            }
        }
    }

    struct AlertContext: Identifiable {
        let id = UUID()
        let title: LocalizedStringKey
        let message: String
    }

    @Published private(set) var permissionStatus: PermissionStatus
    @Published var recordingState: RecordingState = .idle
    @Published var isPreparingSession = false
    @Published var sessionIsPrepared = false
    @Published var alertContext: AlertContext?

    private(set) var recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44_100,
        AVNumberOfChannelsKey: 1,
        AVEncoderBitRateKey: 96_000,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    init(audioSession: AVAudioSession = .sharedInstance()) {
        self.audioSession = audioSession
        self.permissionStatus = PermissionStatus(recordPermission: audioSession.recordPermission)
    }

    private let audioSession: AVAudioSession

    func refreshPermissionStatus() {
        let status = PermissionStatus(recordPermission: audioSession.recordPermission)
        permissionStatus = status

        if status != .granted {
            sessionIsPrepared = false
            recordingState = .idle
        }
    }

    func requestPermission() {
        guard permissionStatus == .notDetermined else { return }

        audioSession.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self = self else { return }
                self.permissionStatus = PermissionStatus(recordPermission: self.audioSession.recordPermission)

                if granted {
                    self.prepareSession()
                } else {
                    self.sessionIsPrepared = false
                    self.recordingState = .idle
                }
            }
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func prepareSession() {
        guard permissionStatus == .granted else { return }
        guard !isPreparingSession else { return }

        isPreparingSession = true
        sessionIsPrepared = false

        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setPreferredSampleRate(44_100)
            try audioSession.setPreferredInputNumberOfChannels(1)
            try audioSession.setActive(true, options: [])

            sessionIsPrepared = true
            recordingState = .idle
        } catch {
            alertContext = AlertContext(
                title: LocalizedStringKey("audio.session.error.title"),
                message: error.localizedDescription
            )
        }

        isPreparingSession = false
    }

    func preview(state: RecordingState) {
        guard sessionIsPrepared else { return }
        recordingState = state
    }
}
