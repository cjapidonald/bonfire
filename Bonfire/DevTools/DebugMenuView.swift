#if DEBUG
import SwiftUI

struct DebugMenuButton: View {
    @ObservedObject private var settings = DebugSettings.shared

    var body: some View {
        Button {
            settings.isMenuPresented = true
        } label: {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 16, weight: .semibold))
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Open Debug Menu"))
    }
}

struct DebugMenuView: View {
    @ObservedObject private var settings = DebugSettings.shared
    @ObservedObject private var performanceSettings = PerformanceSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Data") {
                    Button("Reset Sample Data", role: .destructive) {
                        settings.resetAppData()
                    }
                    Button("Grant Achievements") {
                        settings.grantBadges()
                    }
                    Button("Seed Vocabulary") {
                        settings.seedVocabulary()
                    }
                }

                Section("Connectivity") {
                    Toggle(isOn: $settings.isOffline) {
                        Label("Simulate Offline", systemImage: settings.isOffline ? "wifi.slash" : "wifi")
                    }
                }

                Section("Visual Effects") {
                    Toggle(isOn: Binding(
                        get: { performanceSettings.areParticlesEnabled },
                        set: { settings.setParticlesEnabled($0) }
                    )) {
                        Label("Particles", systemImage: "sparkles")
                    }

                    Toggle(isOn: Binding(
                        get: { performanceSettings.isBlurEnabled },
                        set: { settings.setBlurEnabled($0) }
                    )) {
                        Label("Blur", systemImage: "drop.fill")
                    }
                }
            }
            .navigationTitle("Debug Tools")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        settings.isMenuPresented = false
                    }
                }
            }
        }
    }
}
#endif
