import Foundation

/// Presentation-only localization. Sender status tokens and wire values remain
/// English so status classification, logs and older peers retain their contract.
enum FeatureLocalization {
    static func streamStatus(_ status: String, bundle: Bundle = AppLanguage.bundle) -> String? {
        let pattern = #"^(Extending to|Mirroring to) (.+) \(([0-9]+)×([0-9]+), ([0-9]+) fps target\)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: status, range: NSRange(status.startIndex..., in: status)) else { return nil }
        func group(_ index: Int) -> String {
            guard let range = Range(match.range(at: index), in: status) else { return "" }
            return String(status[range])
        }
        guard let width = Int64(group(3)), let height = Int64(group(4)),
              let rate = Int64(group(5)) else { return nil }
        let kind = group(2) == "device"
            ? String(localized: "Device", table: "FeatureStrings", bundle: bundle,
                     comment: "Generic receiving device name.") : group(2)
        let format = group(1) == "Extending to"
            ? String(localized: "Extending to %@ (%lld×%lld, %lld fps target)",
                     table: "FeatureStrings", bundle: bundle,
                     comment: "Device kind, encoded width, height and target FPS.")
            : String(localized: "Mirroring to %@ (%lld×%lld, %lld fps target)",
                     table: "FeatureStrings", bundle: bundle,
                     comment: "Device kind, encoded width, height and target FPS.")
        return String(format: format, kind, width, height, rate)
    }
}
