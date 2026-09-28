import AppKit
import CoreGraphics

enum ExistingDisplayCatalog {
    static func identifier(_ id: CGDirectDisplayID) -> String? {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return nil }
        return CFUUIDCreateString(nil, uuid) as String
    }

    @MainActor static func read() -> [MirrorDisplaySource] {
        NSScreen.screens.compactMap { screen -> MirrorDisplaySource? in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
                  // A session-owned extension is destroyed when leaving Extend;
                  // do not offer that disappearing target as an existing source.
                  CGDisplayVendorNumber(id) != 0x5043,
                  let uuid = identifier(id), let mode = CGDisplayCopyDisplayMode(id) else { return nil }
            let item = MirrorDisplaySource(id: uuid, name: String(screen.localizedName.prefix(64)),
                pointWidth: mode.width, pointHeight: mode.height,
                pixelWidth: mode.pixelWidth, pixelHeight: mode.pixelHeight, isMain: id == CGMainDisplayID())
            return item.isValid ? item : nil
        }.sorted { a, b in a.isMain != b.isMain ? a.isMain : a.id < b.id }.prefix(8).map { $0 }
    }
}
