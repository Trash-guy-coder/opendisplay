import SwiftUI

private func settingsText(_ key: String) -> String {
    AppLanguage.text(key)
}

/// Shared controls, bound to Mac-owned display preferences.
struct SenderDisplayControls: View {
    @ObservedObject var controller: SenderController
    var body: some View {
        DisplayPreferenceControls(settings: controller.senderSettings, change: controller.applySenderSettings)
    }
}

struct MacSettingsView: View {
    @ObservedObject var controller: SenderController
    @StateObject private var permissions = PermissionMonitor()
    @ObservedObject private var language = AppLanguage.shared

    var body: some View {
        Form {
            Section(settingsText("Language")) { AppLanguagePicker() }
            Section(settingsText("Keyboard & trackpad")) {
                if controller.sessions.isEmpty {
                    Text(settingsText("Connect an iPad to adjust its input and performance settings here."))
                        .foregroundStyle(.secondary)
                }
                ForEach(controller.sessions) { session in
                    RemoteReceiverSettings(session: session, controller: controller)
                }
            }
            Section(settingsText("Display & picture quality")) {
                SenderDisplayControls(controller: controller)
                Text(settingsText("For sharper text, start with Native + Ultra detail + 60 Hz. 4K costs more bandwidth and is downsampled on a lower-resolution iPad screen; 4K does not guarantee 120 fps."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(settingsText("Active streams")) {
                if controller.sessions.isEmpty {
                    Text(settingsText("No active stream. Preferences apply when a device connects."))
                        .foregroundStyle(.secondary)
                }
                ForEach(controller.sessions) { session in
                    StreamSettingsStatus(session: session)
                }
                Text(settingsText("Negotiated dimensions and rate can be lower than your selection. The bitrate target is an encoder budget; live traffic varies with screen content."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(settingsText("Application & display layout")) {
                Picker(settingsText("Show app in"), selection: $controller.presentation) {
                    ForEach(AppPresentation.allCases, id: \.self) { Text(settingsText($0.label)).tag($0) }
                }
                .id(language.selection)
                Button(settingsText("Arrange Displays…")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            Section(settingsText("Permissions & diagnostics")) {
                privacyRow("Screen Recording", granted: permissions.screenRecording, anchor: "Privacy_ScreenCapture")
                privacyRow("Accessibility", granted: permissions.accessibility, anchor: "Privacy_Accessibility")
                Button(settingsText("Local Network settings")) { PermissionMonitor.openPrivacyPane("Privacy_LocalNetwork") }
                Button(settingsText("Show connection logs")) { Log.revealInFinder() }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func privacyRow(_ title: String, granted: Bool, anchor: String) -> some View {
        HStack {
            Label(settingsText(title), systemImage: granted ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(granted ? Color.primary : Color.orange)
            Spacer()
            Button(settingsText("Open system settings")) { PermissionMonitor.openPrivacyPane(anchor) }
        }
    }
}

private struct StreamSettingsStatus: View {
    @ObservedObject private var language = AppLanguage.shared
    @ObservedObject var session: DeviceSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.name).font(.headline)
            Text(FeatureLocalization.streamStatus(session.status) ?? AppLanguage.text(session.status, table: "Localizable"))
                .font(.caption).foregroundStyle(.secondary)
            if let configuration = session.streamConfiguration {
                Text(String(format: settingsText("Negotiated: %d × %d · up to %d fps · target %d Mbps"),
                            configuration.encodedSize.width, configuration.encodedSize.height,
                            configuration.framesPerSecond, configuration.bitrate / 1_000_000))
                    .font(.callout).monospacedDigit()
            }
            Text(String(format: settingsText("Live traffic: %.1f Mbps"), session.mbps))
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

private struct RemoteReceiverSettings: View {
    @ObservedObject var session: DeviceSession
    let controller: SenderController
    @ObservedObject private var language = AppLanguage.shared
    var body: some View {
        if let settings = session.receiverSettings {
            Text(session.name).font(.headline)
            ReceiverNameEditor(name: settings.deviceName ?? session.name) { change(.init(deviceName: $0)) }
            ReceiverInputControls(settings: settings, change: change)
            ReceiverPerformanceControls(settings: settings, change: change)
            Text(settingsText("Changes sync with this iPad. Language and system permissions stay local to each device."))
                .font(.caption).foregroundStyle(.secondary)
        } else {
            Text(settingsText("Waiting for iPad settings. Both apps must support settings sync."))
                .foregroundStyle(.secondary)
        }
    }
    private func change(_ patch: ReceiverSettings) { controller.changeReceiverSettings(patch, session: session) }
}

private struct ReceiverNameEditor: View {
    let name: String
    let change: (String) -> Void
    @State private var draft = ""
    @FocusState private var focused: Bool
    var body: some View {
        TextField(settingsText("Device name"), text: $draft)
            .focused($focused)
            .onAppear { draft = name }
            .onChange(of: name) { value in if !focused { draft = value } }
            .onSubmit { if ReceiverSettings(deviceName: draft).isValidPatch { change(draft) } }
    }
}
