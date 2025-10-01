import AVFoundation
import Combine
import Foundation

final class ReaderAudioController: NSObject, ObservableObject {
    enum State {
        case idle
        case recording
        case playing
    }

    enum PlaybackSpeed: CaseIterable, Identifiable, Hashable {
        case normal
        case medium
        case fast

        var id: Float { rate }

        var rate: Float {
            switch self {
            case .normal:
                return 1.0
            case .medium:
                return 1.25
            case .fast:
                return 1.5
            }
        }

        var label: String {
            switch self {
            case .normal:
                return "1.0×"
            case .medium:
                return "1.25×"
            case .fast:
                return "1.5×"
            }
        }
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var meterLevel: Float = 0
    @Published private(set) var playbackSpeed: PlaybackSpeed = .normal
    @Published private(set) var latestSession: ReaderRecordingSession?

    private let bookID: UUID
    private let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44_100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    private let audioSession: AVAudioSession
    private let recordingStore: ReaderRecordingStore
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var meterTimer: Timer?
    private var playbackTimer: Timer?
    private var recordingURL: URL?
    private var activeRecordingStartDate: Date?
    private var cancellable: AnyCancellable?

    init(book: Book, audioSession: AVAudioSession = .sharedInstance(), recordingStore: ReaderRecordingStore = .shared) {
        self.bookID = book.id
        self.audioSession = audioSession
        self.recordingStore = recordingStore
        super.init()

        latestSession = recordingStore.latestSession(for: bookID)
        duration = latestSession?.duration ?? 0

        let currentBookID = bookID
        cancellable = recordingStore.$sessionsByBook
            .map { $0[currentBookID] ?? [] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                guard let self else { return }
                self.latestSession = sessions.first
                self.duration = sessions.first?.duration ?? 0
                if self.state == .idle {
                    self.elapsedTime = 0
                }
            }
    }

    deinit {
        stop()
    }

    func startRecording() {
        guard state != .recording else { return }

        stopPlayback()
        requestRecordSessionIfNeeded()

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")

        do {
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)

            let recorder = try AVAudioRecorder(url: url, settings: recordingSettings)
            recorder.isMeteringEnabled = true
            recorder.delegate = self
            recorder.record()
            self.recorder = recorder
            recordingURL = url
            state = .recording
            elapsedTime = 0
            meterLevel = 0
            startMeterTimer()
            activeRecordingStartDate = Date()
            AnalyticsLogger.shared.log(
                event: "record_start",
                metadata: [
                    "book_id": bookID.uuidString
                ]
            )
        } catch {
            print("Failed to start recording: \(error)")
            cleanupTemporaryRecording()
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    func startPlayback() {
        guard state != .recording else { return }
        guard let session = latestSession else { return }

        stopPlayback()

        let url = recordingStore.fileURL(for: session)

        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.defaultToSpeaker])
            try audioSession.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.enableRate = true
            player.isMeteringEnabled = true
            player.rate = playbackSpeed.rate
            player.delegate = self
            player.prepareToPlay()
            player.play()
            self.player = player
            state = .playing
            elapsedTime = 0
            duration = player.duration
            meterLevel = 0
            startPlaybackTimer()
        } catch {
            print("Failed to start playback: \(error)")
            stopPlayback()
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    func stop() {
        switch state {
        case .recording:
            stopRecording()
        case .playing:
            stopPlayback()
        case .idle:
            break
        }
    }

    func stopRecording() {
        guard state == .recording else { return }

        recorder?.stop()
        let recordedDuration = recorder?.currentTime ?? elapsedTime
        recorder = nil
        meterTimer?.invalidate()
        meterTimer = nil
        state = .idle
        meterLevel = 0
        elapsedTime = 0
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        var metadata: [String: String] = [
            "book_id": bookID.uuidString,
            "duration_seconds": String(format: "%.2f", recordedDuration)
        ]

        if let startDate = activeRecordingStartDate {
            let elapsed = Date().timeIntervalSince(startDate)
            metadata["elapsed_seconds"] = String(format: "%.2f", elapsed)
        }

        if let url = recordingURL {
            if let session = recordingStore.saveRecording(for: bookID, from: url, duration: recordedDuration) {
                latestSession = session
                self.duration = session.duration
                metadata["session_saved"] = "true"
                metadata["session_id"] = session.id.uuidString
            } else {
                cleanupTemporaryRecording()
                metadata["session_saved"] = "false"
            }
        }

        recordingURL = nil
        activeRecordingStartDate = nil

        AnalyticsLogger.shared.log(event: "record_stop", metadata: metadata)
    }

    func stopPlayback() {
        guard state == .playing else { return }

        player?.stop()
        player = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        state = .idle
        meterLevel = 0
        elapsedTime = 0
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        duration = latestSession?.duration ?? 0
    }

    func togglePlayback() {
        if state == .playing {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    func cyclePlaybackSpeed() {
        let speeds = PlaybackSpeed.allCases
        guard let index = speeds.firstIndex(of: playbackSpeed) else { return }
        let nextIndex = speeds.index(after: index)
        playbackSpeed = speeds[nextIndex == speeds.endIndex ? speeds.startIndex : nextIndex]

        if let player, state == .playing {
            player.rate = playbackSpeed.rate
        }
    }

    func setPlaybackSpeed(_ speed: PlaybackSpeed) {
        playbackSpeed = speed
        if let player, state == .playing {
            player.rate = speed.rate
        }
    }

    func formattedTime(_ time: TimeInterval) -> String {
        let clamped = max(0, time)
        let totalSeconds = Int(round(clamped))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.updateMeter()
        }
        RunLoop.main.add(meterTimer!, forMode: .common)
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
        RunLoop.main.add(playbackTimer!, forMode: .common)
    }

    private func updateMeter() {
        guard let recorder else { return }
        recorder.updateMeters()
        meterLevel = normalized(power: recorder.averagePower(forChannel: 0))
        elapsedTime = recorder.currentTime
    }

    private func updatePlaybackProgress() {
        guard let player else { return }
        player.updateMeters()
        meterLevel = normalized(power: player.averagePower(forChannel: 0))
        elapsedTime = player.currentTime
    }

    private func normalized(power: Float) -> Float {
        let minDb: Float = -80
        guard power > minDb else { return 0 }
        let clamped = min(0, power)
        return (clamped - minDb) / -minDb
    }

    private func cleanupTemporaryRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }

    private func requestRecordSessionIfNeeded() {
        if audioSession.recordPermission == .undetermined {
            audioSession.requestRecordPermission { _ in }
        }
    }
}

extension ReaderAudioController: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Recorder encode error: \(error?.localizedDescription ?? "unknown")")
        stopRecording()
    }
}

extension ReaderAudioController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlayback()
    }
}
