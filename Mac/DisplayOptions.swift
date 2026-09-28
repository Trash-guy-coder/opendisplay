import Foundation

enum DesktopResolution: String, CaseIterable {
    case native, qhd, uhd, fullHD, hd
    var label: String {
        switch self {
        case .native: return String(localized: "Native", table: "DisplayStrings")
        case .qhd: return "2K QHD · 2560 × 1440"
        case .uhd: return "4K UHD · 3840 × 2160"
        case .fullHD: return "1920 × 1080"
        case .hd: return "1280 × 720"
        }
    }
    func pixels(nativeWidth: Int, nativeHeight: Int) -> PixelSize {
        let landscape: PixelSize
        switch self {
        case .native: return PixelSize(width: nativeWidth, height: nativeHeight)
        case .qhd: landscape = PixelSize(width: 2560, height: 1440)
        case .uhd: landscape = PixelSize(width: 3840, height: 2160)
        case .fullHD: landscape = PixelSize(width: 1920, height: 1080)
        case .hd: landscape = PixelSize(width: 1280, height: 720)
        }
        return nativeWidth >= nativeHeight ? landscape
            : PixelSize(width: landscape.height, height: landscape.width)
    }

    var pixelsPerPoint: Int {
        switch self {
        case .native, .qhd, .uhd: return 2
        case .fullHD, .hd: return 1
        }
    }

    /// A larger mirror preset cannot create detail absent from the source.
    /// Preserve the main display's aspect ratio and never upscale its pixels.
    func mirrorPixels(source: PixelSize) -> PixelSize {
        guard source.width > 0, source.height > 0 else { return source }
        let limit = pixels(nativeWidth: source.width, nativeHeight: source.height)
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
    static func select(available: [UInt32], main: UInt32) -> UInt32? {
        available.contains(main) ? main : nil
    }
}
