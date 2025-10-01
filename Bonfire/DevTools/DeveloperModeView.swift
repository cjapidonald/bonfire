import SwiftUI
import UniformTypeIdentifiers

struct DeveloperModeView: View {
    @ObservedObject private var logStore = AnalyticsLogStore.shared
    @State private var exportDocument = AnalyticsLogDocument()
    @State private var isExporting = false
    @State private var exportErrorMessage: String?

    private var events: [AnalyticsLogEvent] {
        logStore.events.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        List {
            Section(header: Text("Analytics Events"), footer: footer) {
                if events.isEmpty {
                    Text("No analytics events recorded yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(event.name)
                                    .font(.headline)
                                Spacer()
                                Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !event.metadata.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(event.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(key)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text(value)
                                                .font(.caption.monospaced())
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Developer Mode")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    exportLogs()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(logStore.events.isEmpty)
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .plainText,
            defaultFilename: "analytics-log.jsonl"
        ) { result in
            if case .failure(let error) = result {
                exportErrorMessage = error.localizedDescription
            }
        }
        .alert("Export Failed", isPresented: Binding(
            get: { exportErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    exportErrorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tap Export to save the analytics log as a JSON Lines file.")
            Text("Events shown newest first. Up to the most recent 500 entries are retained.")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .font(.footnote)
    }

    private func exportLogs() {
        do {
            let data = try logStore.exportJSONLinesData()
            exportDocument = AnalyticsLogDocument(data: data)
            isExporting = true
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }
}

struct AnalyticsLogDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.plainText]

    var data: Data

    init() {
        self.data = Data()
    }

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    NavigationStack {
        DeveloperModeView()
    }
}
