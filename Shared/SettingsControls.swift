import SwiftUI

struct AppLanguagePicker: View {
    @ObservedObject private var language = AppLanguage.shared
    var body: some View {
        Picker(AppLanguage.text("Interface language"), selection: $language.selection) {
            Text(AppLanguage.text("Follow system")).tag("system")
            Text("简体中文").tag("zh-Hans")
            Text("English").tag("en")
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(AppLanguage.text("Interface language"))
    }
}

/// Same input controls on both platforms. Field patches prevent a slider from
/// overwriting a different preference changed by the other device meanwhile.
struct ReceiverInputControls: View {
    @ObservedObject private var language = AppLanguage.shared
    let settings: ReceiverSettings
    let change: (ReceiverSettings) -> Void
    var body: some View {
        Toggle(AppLanguage.text("Keyboard & trackpad input"), isOn: Binding(
            get: { settings.inputEnabled ?? true }, set: { change(.init(inputEnabled: $0)) }))
        Toggle(AppLanguage.text("Swap Command and Option"), isOn: Binding(
            get: { settings.swapCommandAndOption ?? false }, set: { change(.init(swapCommandAndOption: $0)) }))
        Text(AppLanguage.text("Use Option-Tab / Option-Space for Mac app switching / search when swapping is on. Original Command-Tab / Command-Space still belong to iPadOS."))
            .font(.caption).foregroundStyle(.secondary)
        VStack(alignment: .leading) {
            HStack { Text(AppLanguage.text("Pointer speed")); Spacer(); Text(String(format: "%.2f×", settings.pointerSpeed ?? 1.25)).monospacedDigit() }
            Slider(value: Binding(get: { settings.pointerSpeed ?? 1.25 }, set: { change(.init(pointerSpeed: $0)) }), in: 0.5...4, step: 0.05)
                .accessibilityLabel(AppLanguage.text("Pointer speed"))
            HStack { Text(AppLanguage.text("Scroll speed")); Spacer(); Text(String(format: "%.2f×", settings.scrollSpeed ?? 0.5)).monospacedDigit() }
            Slider(value: Binding(get: { settings.scrollSpeed ?? 0.5 }, set: { change(.init(scrollSpeed: $0)) }), in: 0.15...2, step: 0.05)
                .accessibilityLabel(AppLanguage.text("Scroll speed"))
        }
        Toggle(AppLanguage.text("Reverse scroll direction"), isOn: Binding(
            get: { settings.reverseScroll ?? false }, set: { change(.init(reverseScroll: $0)) }))
        Button(AppLanguage.text("Reset trackpad settings")) {
            change(.init(pointerSpeed: 1.25, scrollSpeed: 0.5, reverseScroll: false))
        }
    }
}

struct ReceiverPerformanceControls: View {
    @ObservedObject private var language = AppLanguage.shared
    let settings: ReceiverSettings
    let change: (ReceiverSettings) -> Void
    var body: some View {
        Toggle(AppLanguage.text("Performance overlay"), isOn: Binding(
            get: { settings.showAnalytics ?? false }, set: { change(.init(showAnalytics: $0)) }))
        Toggle(AppLanguage.text("Metal renderer (experimental)"), isOn: Binding(
            get: { settings.metalRenderer ?? false }, set: { change(.init(metalRenderer: $0)) }))
    }
}

struct DisplayPreferenceControls: View {
    @State private var editingCustom = false
    @ObservedObject private var language = AppLanguage.shared
    let settings: SenderSettings
    let change: (SenderSettings) -> Void
    var body: some View {
        Picker(AppLanguage.text("Mode"), selection: Binding(get: { settings.mode ?? "extend" }, set: { change(.init(mode: $0)) })) {
            Text(AppLanguage.text("Extend")).tag("extend")
            Text(AppLanguage.text("Mirror")).tag("mirror")
        }.pickerStyle(.segmented)
        if settings.mode == "mirror" {
            Picker(AppLanguage.text("Mirror display"), selection: Binding(
                get: { selectedMirrorKey }, set: { change(.init(mirrorDisplayID: $0)) })) {
                if mirrorDisplays.isEmpty {
                    Text(AppLanguage.text("Waiting for Mac displays…")).tag(selectedMirrorKey)
                } else {
                    if !mirrorDisplays.contains(where: { $0.id == selectedMirrorKey }) {
                        Text(AppLanguage.text("Selected display unavailable")).tag(selectedMirrorKey)
                    }
                    ForEach(mirrorDisplays) { Text($0.label).tag($0.id) }
                }
            }
            .id("mirror-display-\(language.selection)")
            .disabled(mirrorDisplays.isEmpty)
            if let source = mirrorDisplays.first(where: { $0.id == selectedMirrorKey }) {
                Text(String(format: AppLanguage.text("Source desktop: %d × %d pt · %d × %d pixels"),
                            source.pointWidth, source.pointHeight, source.pixelWidth, source.pixelHeight))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(AppLanguage.text("Select an existing physical or virtual Mac display to mirror. This does not create or resize a display. Extend remains a separate mode."))
                .font(.caption).foregroundStyle(.secondary)
        }
        Picker(AppLanguage.text("Resolution"), selection: Binding(
            get: { editingCustom ? "custom" : settings.resolution ?? "native" },
            set: { value in
                editingCustom = value == "custom"
                if !editingCustom { change(.init(resolution: value)) }
            })) {
            Text(nativeLabel).tag("native")
            ForEach(ResolutionPreset.iPadPresets, id: \.self) { Text($0.label).tag($0.rawValue) }
            ForEach(ResolutionPreset.standardPresets, id: \.self) { Text($0.label).tag($0.rawValue) }
            Text(AppLanguage.text("Custom resolution…")).tag("custom")
        }
        .id("resolution-\(language.selection)")
        if let width = settings.nativeWidth, let height = settings.nativeHeight {
            Text(String(format: AppLanguage.text("Connected device native pixels: %d × %d"), width, height))
                .font(.caption).foregroundStyle(.secondary)
        }
        if editingCustom || settings.resolution == "custom" {
            CustomResolutionEditor(settings: settings) { value in
                change(.init(resolution: "custom", customWidth: value.width, customHeight: value.height))
                editingCustom = false
            }
        }
        Picker(AppLanguage.text("Frame-rate limit"), selection: Binding(get: { settings.refreshRate ?? 60 }, set: { change(.init(refreshRate: $0)) })) {
            ForEach([30, 60, 90, 120], id: \.self) { Text("\($0) Hz").tag($0) }
        }
        Picker(AppLanguage.text("Quality"), selection: Binding(get: { settings.quality ?? "best" }, set: { change(.init(quality: $0)) })) {
            Text(AppLanguage.text("Ultra detail")).tag("ultra")
            Text(AppLanguage.text("Best")).tag("best")
            Text(AppLanguage.text("Balanced")).tag("balanced")
            Text(AppLanguage.text("Fast")).tag("fast")
        }
        Toggle(AppLanguage.text("Low-latency cursor"), isOn: Binding(get: { settings.lowLatencyCursor ?? true }, set: { change(.init(lowLatencyCursor: $0)) }))
        Text(AppLanguage.text("In Extend mode, presets create a HiDPI desktop at the selected pixels and follow device rotation. Mirror preserves the selected display's pixels and aspect ratio. Device and codec limits may reduce the transmitted size or frame rate."))
            .font(.caption).foregroundStyle(.secondary)
    }

    private var nativeLabel: String {
        if settings.mode == "mirror", let source = mirrorDisplays.first(where: { $0.id == selectedMirrorKey }) {
            return String(format: AppLanguage.text("Native · %d × %d (selected display)"), source.pixelWidth, source.pixelHeight)
        }
        guard let width = settings.nativeWidth, let height = settings.nativeHeight else {
            return AppLanguage.text("Native (automatic)")
        }
        return String(format: AppLanguage.text("Native · %d × %d (receiver)"), width, height)
    }

    private var mirrorDisplays: [MirrorDisplaySource] { settings.availableMirrorDisplays ?? [] }
    private var selectedMirrorKey: String {
        let value = settings.mirrorDisplayID ?? "main"
        return value == "main" ? mirrorDisplays.first(where: \.isMain)?.id ?? "main" : value
    }
}

private struct CustomResolutionEditor: View {
    @ObservedObject private var language = AppLanguage.shared
    let settings: SenderSettings
    let apply: (CustomResolution) -> Void
    @State private var width = ""
    @State private var height = ""
    @FocusState private var focused: Bool
    private var value: CustomResolution? { CustomResolution.parse(width: width, height: height) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField(AppLanguage.text("Width (pixels)"), text: $width)
                    .focused($focused)
                    .accessibilityLabel(AppLanguage.text("Width (pixels)"))
                Text("×")
                TextField(AppLanguage.text("Height (pixels)"), text: $height)
                    .focused($focused)
                    .accessibilityLabel(AppLanguage.text("Height (pixels)"))
            }
            .textFieldStyle(.roundedBorder)
            Text(AppLanguage.text("Enter 320–8192 pixels per side, in multiples of 4 for exact HiDPI pixels. Orientation follows the receiving device. Editing does not reconnect until Apply."))
                .font(.caption).foregroundStyle(.secondary)
            if value == nil && (!width.isEmpty || !height.isEmpty) {
                Text(AppLanguage.text("Enter valid pixel dimensions before applying."))
                    .font(.caption).foregroundStyle(.red)
            }
            HStack {
                if let w = settings.nativeWidth, let h = settings.nativeHeight {
                    Button(AppLanguage.text("Use device native size")) {
                        width = String(max(w, h)); height = String(min(w, h))
                    }
                }
                Spacer()
                Button(AppLanguage.text("Apply custom resolution")) {
                    if let value { focused = false; apply(value) }
                }.disabled(value == nil)
            }
        }
        .onAppear { load() }
        .onChange(of: settings.customResolution) { _ in if !focused { load() } }
    }

    private func load() {
        let saved = settings.customResolution ?? .defaultValue
        width = String(saved.width); height = String(saved.height)
    }
}
