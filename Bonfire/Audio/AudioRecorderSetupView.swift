import SwiftUI

struct AudioRecorderSetupView: View {
    @StateObject private var viewModel = AudioRecorderSetupViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.xl) {
                header
                permissionSection
                sessionSection
                statesSection
                planSection
            }
            .padding(DesignSpacing.xl)
        }
        .background(DesignColor.deepWalnut.ignoresSafeArea())
        .onAppear { viewModel.refreshPermissionStatus() }
        .alert(item: $viewModel.alertContext) { context in
            Alert(title: Text(context.title), message: Text(context.message), dismissButton: .default(Text("OK")))
        }
        .navigationTitle(Text("audio.title"))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.sm) {
            Text("audio.title")
                .font(DesignTypography.Display.font)
                .foregroundColor(DesignColor.amberGlow)
            Text("audio.subtitle")
                .font(DesignTypography.Body.font)
                .foregroundColor(DesignColor.agedParchment.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var permissionSection: some View {
        ParchmentPage {
            VStack(alignment: .leading, spacing: DesignSpacing.md) {
                Label {
                    VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                        Text("audio.permission.title")
                            .font(DesignTypography.Title.font)
                            .foregroundColor(DesignColor.ink)
                        Text("audio.permission.message")
                            .font(DesignTypography.Body.font)
                            .foregroundColor(DesignColor.ink.opacity(0.7))
                    }
                } icon: {
                    Image(systemName: "mic")
                        .font(.system(size: 28))
                        .foregroundColor(DesignColor.amberGlow)
                        .accessibilityHidden(true)
                }

                permissionStatusView
                permissionActionButton
            }
        }
    }

    @ViewBuilder
    private var permissionStatusView: some View {
        HStack(spacing: DesignSpacing.sm) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            Text(permissionStatusText)
                .font(DesignTypography.Body.font)
                .foregroundColor(DesignColor.ink.opacity(0.8))
        }
        .accessibilityElement(children: .combine)
    }

    private var permissionActionButton: some View {
        Group {
            switch viewModel.permissionStatus {
            case .notDetermined:
                actionButton(
                    titleKey: "audio.permission.button.request",
                    icon: "hand.tap",
                    isEnabled: true,
                    action: viewModel.requestPermission
                )
            case .denied:
                actionButton(
                    titleKey: "audio.permission.button.settings",
                    icon: "gearshape",
                    action: viewModel.openSettings
                )
            case .granted:
                EmptyView()
            }
        }
    }

    private var sessionSection: some View {
        ParchmentPage {
            VStack(alignment: .leading, spacing: DesignSpacing.md) {
                Label("audio.session.title", systemImage: "shield.checkerboard")
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.ink)
                Text("audio.session.message")
                    .font(DesignTypography.Body.font)
                    .foregroundColor(DesignColor.ink.opacity(0.7))

                if viewModel.permissionStatus == .granted {
                    actionButton(
                        titleKey: viewModel.sessionIsPrepared ? "audio.session.button.rearm" : "audio.session.button.arm",
                        icon: "bolt.horizontal.circle",
                        isEnabled: !viewModel.isPreparingSession,
                        action: viewModel.prepareSession
                    )
                }

                sessionStatusView
            }
        }
    }

    @ViewBuilder
    private var sessionStatusView: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            if viewModel.permissionStatus != .granted {
                Text("audio.session.status.permission")
                    .font(DesignTypography.Caption.font)
                    .foregroundColor(DesignColor.ink.opacity(0.6))
            } else if viewModel.sessionIsPrepared {
                Text("audio.session.status.ready")
                    .font(DesignTypography.Caption.font)
                    .foregroundColor(DesignColor.ink.opacity(0.8))
            } else if viewModel.isPreparingSession {
                ProgressView {
                    Text("audio.session.status.preparing")
                        .font(DesignTypography.Caption.font)
                        .foregroundColor(DesignColor.ink.opacity(0.7))
                }
            } else {
                Text("audio.session.status.prompt")
                    .font(DesignTypography.Caption.font)
                    .foregroundColor(DesignColor.ink.opacity(0.6))
            }
        }
    }

    private var statesSection: some View {
        ParchmentPage {
            VStack(alignment: .leading, spacing: DesignSpacing.md) {
                Text("audio.state.title")
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.ink)
                Text("audio.state.description")
                    .font(DesignTypography.Body.font)
                    .foregroundColor(DesignColor.ink.opacity(0.7))

                stateGrid
            }
        }
    }

    private var stateGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: DesignSpacing.md)], spacing: DesignSpacing.md) {
            ForEach(AudioRecorderSetupViewModel.RecordingState.allCases) { state in
                Button {
                    viewModel.preview(state: state)
                } label: {
                    RecordingStateBadge(state: state, isActive: viewModel.recordingState == state)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.sessionIsPrepared)
            }
        }
    }

    private var planSection: some View {
        ParchmentPage {
            VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                Text("audio.plan.title")
                    .font(DesignTypography.Title.font)
                    .foregroundColor(DesignColor.ink)
                Text("audio.plan.description")
                    .font(DesignTypography.Body.font)
                    .foregroundColor(DesignColor.ink.opacity(0.7))

                planRow(titleKey: "audio.plan.format", value: "AAC (.m4a)")
                planRow(titleKey: "audio.plan.channels", value: "1")
                planRow(titleKey: "audio.plan.sampleRate", value: "44,100 Hz")
                planRow(titleKey: "audio.plan.bitRate", value: "96 kbps")
            }
        }
    }

    private func planRow(titleKey: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(titleKey)
                .font(DesignTypography.Body.font)
                .foregroundColor(DesignColor.ink.opacity(0.7))
            Spacer()
            Text(value)
                .font(DesignTypography.Body.font)
                .foregroundColor(DesignColor.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private func actionButton(titleKey: LocalizedStringKey, icon: String, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(titleKey)
                    .font(DesignTypography.Title.font)
                Spacer()
            }
            .foregroundColor(DesignColor.ink)
            .padding(.horizontal, DesignSpacing.lg)
            .padding(.vertical, DesignSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignCornerRadius.pill)
                    .fill(
                        LinearGradient(
                            colors: [DesignColor.aquaGlow.opacity(0.95), DesignColor.aquaGlow.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isEnabled ? 1 : 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignCornerRadius.pill)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: DesignColor.aquaGlow.opacity(isEnabled ? 0.4 : 0.15), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private var permissionStatusText: LocalizedStringKey {
        switch viewModel.permissionStatus {
        case .notDetermined:
            return LocalizedStringKey("audio.permission.status.pending")
        case .denied:
            return LocalizedStringKey("audio.permission.status.denied")
        case .granted:
            return LocalizedStringKey("audio.permission.status.granted")
        }
    }

    private var statusIcon: String {
        switch viewModel.permissionStatus {
        case .notDetermined:
            return "questionmark.circle"
        case .denied:
            return "xmark.octagon"
        case .granted:
            return "checkmark.circle"
        }
    }

    private var statusColor: Color {
        switch viewModel.permissionStatus {
        case .notDetermined:
            return DesignColor.amberGlow
        case .denied:
            return Color.red
        case .granted:
            return DesignColor.aquaGlow
        }
    }
}

private struct RecordingStateBadge: View {
    let state: AudioRecorderSetupViewModel.RecordingState
    let isActive: Bool

    var body: some View {
        VStack(spacing: DesignSpacing.sm) {
            Image(systemName: state.icon)
                .font(.system(size: 28))
                .foregroundColor(isActive ? DesignColor.aquaGlow : DesignColor.ink.opacity(0.6))
            Text(state.localizedKey)
                .font(DesignTypography.Body.font)
                .foregroundColor(DesignColor.ink)
        }
        .padding(DesignSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignCornerRadius.soft)
                .fill(DesignColor.agedParchment.opacity(isActive ? 1 : 0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignCornerRadius.soft)
                .stroke(isActive ? DesignColor.aquaGlow : DesignColor.ink.opacity(0.1), lineWidth: 2)
        )
        .shadow(color: isActive ? DesignColor.aquaGlow.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

struct AudioRecorderSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AudioRecorderSetupView()
        }
        .environmentObject(LanguageManager())
    }
}
