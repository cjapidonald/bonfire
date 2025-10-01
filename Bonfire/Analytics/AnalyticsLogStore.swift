import Foundation

struct AnalyticsLogEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let timestamp: Date
    let metadata: [String: String]
}

final class AnalyticsLogStore: ObservableObject {
    static let shared = AnalyticsLogStore()

    @Published private(set) var events: [AnalyticsLogEvent] = []

    private let queue = DispatchQueue(label: "com.bonfire.analyticslogstore", qos: .utility)
    private let maxEvents = 500
    private var storage: [AnalyticsLogEvent] = []

    private init() {}

    func record(event name: String, metadata: [String: String]) {
        let event = AnalyticsLogEvent(
            id: UUID(),
            name: name,
            timestamp: Date(),
            metadata: metadata
        )

        queue.async {
            self.storage.append(event)
            if self.storage.count > self.maxEvents {
                self.storage.removeFirst(self.storage.count - self.maxEvents)
            }

            let snapshot = self.storage
            DispatchQueue.main.async {
                self.events = snapshot
            }
        }
    }

    func snapshot() -> [AnalyticsLogEvent] {
        queue.sync { storage }
    }

    func exportJSONLinesData() throws -> Data {
        let snapshot = snapshot()
        guard !snapshot.isEmpty else {
            return Data()
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let lines = try snapshot.map { event -> String in
            let payload = AnalyticsLogPayload(event: event)
            let data = try encoder.encode(payload)
            guard let line = String(data: data, encoding: .utf8) else {
                throw AnalyticsLogStoreError.encodingFailed
            }
            return line
        }

        let joined = lines.joined(separator: "\n")
        guard let data = joined.data(using: .utf8) else {
            throw AnalyticsLogStoreError.encodingFailed
        }

        return data
    }
}

private struct AnalyticsLogPayload: Codable {
    let event: String
    let timestamp: Date
    let metadata: [String: String]

    init(event: AnalyticsLogEvent) {
        self.event = event.name
        self.timestamp = event.timestamp
        self.metadata = event.metadata
    }
}

enum AnalyticsLogStoreError: Error {
    case encodingFailed
}

extension AnalyticsLogStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode analytics log entries."
        }
    }
}
