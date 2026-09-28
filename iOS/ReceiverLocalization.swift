import Foundation

/// Explicit lookup for runtime Strings; SwiftUI literals use the same catalog.
enum ReceiverLocalization {
    static func text(_ key: String, bundle: Bundle = AppLanguage.bundle) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func format(_ key: String, _ values: CVarArg..., bundle: Bundle = AppLanguage.bundle) -> String {
        String(format: text(key, bundle: bundle), locale: Locale.current, arguments: values)
    }

    static func status(_ value: String, bundle: Bundle = AppLanguage.bundle) -> String {
        for (prefix, key) in [("Listening on :", "Listening on :%@"),
                              ("Receiving ", "Receiving %@"),
                              ("Listener failed: ", "Listener failed: %@")] {
            if value.hasPrefix(prefix) {
                return format(key, String(value.dropFirst(prefix.count)), bundle: bundle)
            }
        }
        return text(value, bundle: bundle)
    }
}
