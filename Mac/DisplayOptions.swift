import Foundation

typealias DesktopResolution = ResolutionPreset

extension ResolutionPreset {
    func pixels(nativeWidth: Int, nativeHeight: Int,
                custom: CustomResolution = .defaultValue) -> PixelSize {
        if self == .native { return PixelSize(width: nativeWidth, height: nativeHeight) }
        let size: (width: Int, height: Int)
        if self == .custom {
            guard custom.isValid else { return PixelSize(width: 0, height: 0) }
            size = (max(custom.width, custom.height), min(custom.width, custom.height))
        } else {
            guard let fixed = fixedPixels else { return PixelSize(width: 0, height: 0) }
            size = fixed
        }
        return nativeWidth >= nativeHeight ? PixelSize(width: size.width, height: size.height)
            : PixelSize(width: size.height, height: size.width)
    }

    var pixelsPerPoint: Int {
        switch self {
        case .fullHD, .hd: return 1
        default: return 2
        }
    }

    /// A larger mirror preset cannot create detail absent from the source.
    /// Preserve the main display's aspect ratio and never upscale its pixels.
    func mirrorPixels(source: PixelSize, custom: CustomResolution = .defaultValue) -> PixelSize {
        guard source.width > 0, source.height > 0 else { return source }
        let limit = pixels(nativeWidth: source.width, nativeHeight: source.height, custom: custom)
        guard limit.width > 0, limit.height > 0 else { return PixelSize(width: 0, height: 0) }
        let scale = min(1, min(Double(limit.width) / Double(source.width),
                               Double(limit.height) / Double(source.height)))
        return PixelSize(width: max(2, Int(Double(source.width) * scale) & ~1),
                         height: max(2, Int(Double(source.height) * scale) & ~1))
    }
}

enum DisplayRefreshRate: Int, CaseIterable {
    case hz30 = 30, hz60 = 60, hz90 = 90, hz120 = 120
    var label: String { "\(rawValue) Hz" }
}

enum MirrorDisplaySelection {
    static func select(available: [UInt32], main: UInt32, preference: String = "main",
                       uuidByID: [UInt32: String] = [:]) -> UInt32? {
        if preference == "main" { return available.contains(main) ? main : nil }
        // Never silently capture the physical main screen when a specifically
        // selected virtual display disappears.
        return available.first { uuidByID[$0]?.caseInsensitiveCompare(preference) == .orderedSame }
    }
}
