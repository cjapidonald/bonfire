import Foundation

/// A lightweight analytics logger that records events to the console.
final class AnalyticsLogger {
    static let shared = AnalyticsLogger()

    private init() {}

    /// Logs an analytics event with optional metadata.
    /// - Parameters:
    ///   - event: The event name to log.
    ///   - metadata: Additional key-value pairs for context.
    func log(event: String, metadata: [String: String] = [:]) {
        AnalyticsLogStore.shared.record(event: event, metadata: metadata)

        let metadataDescription = metadata
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: " ")

        if metadataDescription.isEmpty {
            print("[Analytics] event=\(event)")
        } else {
            print("[Analytics] event=\(event) \(metadataDescription)")
        }
    }
}
