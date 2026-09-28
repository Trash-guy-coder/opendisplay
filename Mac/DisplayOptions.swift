import Foundation

enum DesktopResolution: String, CaseIterable {
    case native, fullHD, hd
    var label: String {
        switch self {
        case .native: return String(localized: "Native", table: "DisplayStrings")
        case .fullHD: return "1920 × 1080"
        case .hd: return "1280 × 720"
        }
    }
    func pixels(nativeWidth: Int, nativeHeight: Int) -> PixelSize {
        let landscape: PixelSize
        switch self {
        case .native: return PixelSize(width: nativeWidth, height: nativeHeight)
        case .fullHD: landscape = PixelSize(width: 1920, height: 1080)
        case .hd: landscape = PixelSize(width: 1280, height: 720)
        }
        return nativeWidth >= nativeHeight ? landscape
            : PixelSize(width: landscape.height, height: landscape.width)
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
