import Foundation

/// Physical pixel dimensions, not UIKit points. Model labels deliberately name
/// a generation: panels within one iPad family do not all have the same raster.
enum ResolutionPreset: String, CaseIterable {
    case native
    case ipad102, ipadA16, air11, air13, pro11, pro11OLED, pro129, pro13OLED
    case qhd, uhd, fullHD, hd, custom

    static let iPadPresets: [Self] = [.ipad102, .ipadA16, .air11, .air13, .pro11, .pro11OLED, .pro129, .pro13OLED]
    static let standardPresets: [Self] = [.qhd, .uhd, .fullHD, .hd]

    var fixedPixels: (width: Int, height: Int)? {
        switch self {
        case .ipad102: return (2160, 1620)
        case .ipadA16, .air11: return (2360, 1640)
        case .air13, .pro129: return (2732, 2048)
        case .pro11: return (2388, 1668)
        case .pro11OLED: return (2420, 1668)
        case .pro13OLED: return (2752, 2064)
        case .qhd: return (2560, 1440)
        case .uhd: return (3840, 2160)
        case .fullHD: return (1920, 1080)
        case .hd: return (1280, 720)
        case .native, .custom: return nil
        }
    }
    var label: String {
        let name: String
        switch self {
        case .native: return AppLanguage.text("Native")
        case .custom: return AppLanguage.text("Custom resolution…")
        case .ipad102: name = AppLanguage.text("iPad 10.2-inch (9th gen)")
        case .ipadA16: name = "iPad (A16)"
        case .air11: name = AppLanguage.text("iPad Air 11-inch (M3)")
        case .air13: name = AppLanguage.text("iPad Air 13-inch (M3)")
        case .pro11: name = AppLanguage.text("iPad Pro 11-inch (4th gen)")
        case .pro11OLED: name = AppLanguage.text("iPad Pro 11-inch (M4)")
        case .pro129: name = AppLanguage.text("iPad Pro 12.9-inch (6th gen)")
        case .pro13OLED: name = AppLanguage.text("iPad Pro 13-inch (M4)")
        case .qhd: name = "2K QHD"
        case .uhd: name = "4K UHD"
        case .fullHD, .hd: name = ""
        }
        guard let size = fixedPixels else { return name }
        return (name.isEmpty ? "" : name + " · ") + "\(size.width) × \(size.height)"
    }
}

struct CustomResolution: Equatable, Codable {
    let width: Int
    let height: Int
    static let defaultValue = Self(width: 2560, height: 1600)
    // Two even logical dimensions at 2× HiDPI preserve the requested pixels.
    var isValid: Bool {
        (320...8192).contains(width) && (320...8192).contains(height)
            && width % 4 == 0 && height % 4 == 0
    }
    static func parse(width: String, height: String) -> Self? {
        guard let w = Int(width.trimmingCharacters(in: .whitespaces)),
              let h = Int(height.trimmingCharacters(in: .whitespaces)) else { return nil }
        let result = Self(width: w, height: h)
        return result.isValid ? result : nil
    }
}
