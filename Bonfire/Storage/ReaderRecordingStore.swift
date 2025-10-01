import Combine
import Foundation

struct ReaderRecordingSession: Identifiable, Codable, Equatable {
    let id: UUID
    let bookID: UUID
    let createdAt: Date
    let duration: TimeInterval
    fileprivate let fileName: String

    init(id: UUID = UUID(), bookID: UUID, createdAt: Date = Date(), duration: TimeInterval, fileName: String) {
        self.id = id
        self.bookID = bookID
        self.createdAt = createdAt
        self.duration = duration
        self.fileName = fileName
    }
}

final class ReaderRecordingStore: ObservableObject {
    static let shared = ReaderRecordingStore()

    @Published private(set) var sessionsByBook: [UUID: [ReaderRecordingSession]]

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let metadataKey = "reader.recordings.metadata"
    private let directoryURL: URL
    private let retentionLimit = 10

    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            directoryURL = documents.appendingPathComponent("ReaderRecordings", isDirectory: true)
        } else {
            directoryURL = fileManager.temporaryDirectory.appendingPathComponent("ReaderRecordings", isDirectory: true)
        }

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        if let data = userDefaults.data(forKey: metadataKey),
           let decoded = try? decoder.decode([String: [ReaderRecordingSession]].self, from: data) {
            sessionsByBook = decoded.reduce(into: [:]) { partialResult, entry in
                guard let bookID = UUID(uuidString: entry.key) else { return }
                partialResult[bookID] = entry.value.sorted(by: { $0.createdAt > $1.createdAt })
            }
        } else {
            sessionsByBook = [:]
        }

        cleanupMissingFiles()
    }

    func sessions(for bookID: UUID) -> [ReaderRecordingSession] {
        sessionsByBook[bookID] ?? []
    }

    func latestSession(for bookID: UUID) -> ReaderRecordingSession? {
        sessions(for: bookID).first
    }

    func fileURL(for session: ReaderRecordingSession) -> URL {
        directoryURL.appendingPathComponent(session.fileName)
    }

    @discardableResult
    func saveRecording(for bookID: UUID, from temporaryURL: URL, duration: TimeInterval) -> ReaderRecordingSession? {
        let fileName = "\(UUID().uuidString).m4a"
        let destinationURL = directoryURL.appendingPathComponent(fileName)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        } catch {
            print("Failed to persist recording: \(error)")
            try? fileManager.removeItem(at: temporaryURL)
            return nil
        }

        var sessions = sessionsByBook[bookID] ?? []
        let session = ReaderRecordingSession(bookID: bookID, duration: duration, fileName: fileName)
        sessions.insert(session, at: 0)
        sessionsByBook[bookID] = sessions

        enforceRetention(for: bookID)
        persist()
        return session
    }

    private func enforceRetention(for bookID: UUID) {
        guard var sessions = sessionsByBook[bookID] else { return }

        if sessions.count > retentionLimit {
            let overflow = sessions.suffix(from: retentionLimit)
            overflow.forEach { deleteFile(for: $0) }
            sessions = Array(sessions.prefix(retentionLimit))
            sessionsByBook[bookID] = sessions
        }
    }

    private func persist() {
        let payload = sessionsByBook.reduce(into: [String: [ReaderRecordingSession]]()) { partialResult, entry in
            partialResult[entry.key.uuidString] = entry.value
        }

        do {
            let data = try encoder.encode(payload)
            userDefaults.set(data, forKey: metadataKey)
        } catch {
            print("Failed to persist recording metadata: \(error)")
        }
    }

    private func cleanupMissingFiles() {
        var updated: [UUID: [ReaderRecordingSession]] = [:]

        for (bookID, sessions) in sessionsByBook {
            let retained = sessions.filter { session in
                let url = fileURL(for: session)
                return fileManager.fileExists(atPath: url.path)
            }
            if !retained.isEmpty {
                updated[bookID] = retained
            }
        }

        sessionsByBook = updated
        persist()
    }

    private func deleteFile(for session: ReaderRecordingSession) {
        let url = fileURL(for: session)
        try? fileManager.removeItem(at: url)
    }
}
