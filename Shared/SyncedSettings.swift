import Foundation

/// Optional settings capability, independent of video/input protocol numbers.
/// Requests contain only changed fields, so unrelated local edits survive.
enum SettingsSync {
    static let version = 3
    static let receiverState = "receiverSettings"
    static let receiverChange = "setReceiverSettings"
    static let senderState = "senderSettings"
    static let senderChange = "setSenderSettings"
    private struct Envelope<T: Codable>: Codable {
        let type: String
        let settingsVersion: Int
        let values: T
    }
    static func json<T: Codable>(_ value: T, type: String) -> String? {
        guard let data = try? JSONEncoder().encode(Envelope(type: type, settingsVersion: version, values: value)) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func decode<T: Codable>(_ type: T.Type, data: Data, message: String) -> T? {
        guard data.count <= 4096,
              let result = try? JSONDecoder().decode(Envelope<T>.self, from: data),
              result.settingsVersion == version, result.type == message else { return nil }
        return result.values
    }
}

struct ReceiverSettings: Codable, Equatable {
    var inputEnabled: Bool?
    var swapCommandAndOption: Bool?
    var pointerSpeed: Double?
    var scrollSpeed: Double?
    var reverseScroll: Bool?
    var showAnalytics: Bool?
    var metalRenderer: Bool?
    var deviceName: String?

    var isValid: Bool {
        let notEmpty = inputEnabled != nil || swapCommandAndOption != nil || pointerSpeed != nil
            || scrollSpeed != nil || reverseScroll != nil || showAnalytics != nil
            || metalRenderer != nil || deviceName != nil
        return notEmpty
            && (pointerSpeed.map { $0.isFinite && (0.5...4).contains($0) } ?? true)
    }
    var isValidPatch: Bool {
        isValid && (scrollSpeed.map { $0.isFinite && (0.15...2).contains($0) } ?? true)
            && (deviceName.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 120 } ?? true)
    }
    var isComplete: Bool {
        isValidPatch && inputEnabled != nil && swapCommandAndOption != nil && pointerSpeed != nil
            && scrollSpeed != nil && reverseScroll != nil && showAnalytics != nil && metalRenderer != nil && deviceName != nil
    }
    func merging(_ patch: Self) -> Self {
        .init(inputEnabled: patch.inputEnabled ?? inputEnabled,
              swapCommandAndOption: patch.swapCommandAndOption ?? swapCommandAndOption,
              pointerSpeed: patch.pointerSpeed ?? pointerSpeed, scrollSpeed: patch.scrollSpeed ?? scrollSpeed,
              reverseScroll: patch.reverseScroll ?? reverseScroll, showAnalytics: patch.showAnalytics ?? showAnalytics,
              metalRenderer: patch.metalRenderer ?? metalRenderer, deviceName: patch.deviceName ?? deviceName)
    }
    static func read(from defaults: UserDefaults = .standard, fallbackName: String) -> Self {
        .init(inputEnabled: defaults.object(forKey: "hardwareInputEnabled") as? Bool ?? true,
              swapCommandAndOption: defaults.bool(forKey: "swapCommandAndOption"),
              pointerSpeed: defaults.object(forKey: "trackpadPointerSpeed") as? Double ?? 1.25,
              scrollSpeed: defaults.object(forKey: "trackpadScrollSpeed") as? Double ?? 0.5,
              reverseScroll: defaults.bool(forKey: "trackpadReverseScroll"),
              showAnalytics: defaults.bool(forKey: "showAnalytics"),
              metalRenderer: defaults.bool(forKey: "metalRenderer"),
              deviceName: defaults.string(forKey: "deviceName").flatMap { $0.isEmpty ? nil : $0 } ?? fallbackName)
    }
    func apply(to defaults: UserDefaults = .standard) {
        guard isValidPatch else { return }
        if let inputEnabled { defaults.set(inputEnabled, forKey: "hardwareInputEnabled") }
        if let swapCommandAndOption { defaults.set(swapCommandAndOption, forKey: "swapCommandAndOption") }
        if let pointerSpeed { defaults.set(pointerSpeed, forKey: "trackpadPointerSpeed") }
        if let scrollSpeed { defaults.set(scrollSpeed, forKey: "trackpadScrollSpeed") }
        if let reverseScroll { defaults.set(reverseScroll, forKey: "trackpadReverseScroll") }
        if let showAnalytics { defaults.set(showAnalytics, forKey: "showAnalytics") }
        if let metalRenderer { defaults.set(metalRenderer, forKey: "metalRenderer") }
        if let deviceName { defaults.set(deviceName, forKey: "deviceName") }
    }
}

struct SenderSettings: Codable, Equatable {
    var mode: String?
    var resolution: String?
    var refreshRate: Int?
    var quality: String?
    var lowLatencyCursor: Bool?
    var customWidth: Int?
    var customHeight: Int?
    // Read-only snapshot metadata. A request never changes device dimensions.
    var nativeWidth: Int?
    var nativeHeight: Int?
    var mirrorDisplayID: String?
    var availableMirrorDisplays: [MirrorDisplaySource]?
    var customResolution: CustomResolution? {
        guard let width = customWidth, let height = customHeight else { return nil }
        return CustomResolution(width: width, height: height)
    }
    var isValid: Bool {
        (mode != nil || resolution != nil || refreshRate != nil || quality != nil || lowLatencyCursor != nil || customWidth != nil || customHeight != nil || mirrorDisplayID != nil)
            && (mode.map { ["mirror", "extend"].contains($0) } ?? true)
            && (resolution.map { ResolutionPreset(rawValue: $0) != nil } ?? true)
            && (refreshRate.map { [30, 60, 90, 120].contains($0) } ?? true)
            && (quality.map { ["ultra", "best", "balanced", "fast"].contains($0) } ?? true)
            && (mirrorDisplayID.map { $0 == "main" || UUID(uuidString: $0) != nil } ?? true)
            && (availableMirrorDisplays.map { $0.count <= 8 && $0.allSatisfy(\.isValid) } ?? true)
            && ((customWidth == nil && customHeight == nil) || customResolution?.isValid == true)
            && (resolution != "custom" || customResolution?.isValid == true)
            && ((nativeWidth == nil && nativeHeight == nil)
                || ((nativeWidth ?? 0) > 0 && (nativeWidth ?? 0) <= 16384
                    && (nativeHeight ?? 0) > 0 && (nativeHeight ?? 0) <= 16384))
    }
    var isComplete: Bool {
        isValid && mode != nil && resolution != nil && refreshRate != nil && quality != nil && lowLatencyCursor != nil
    }
}
