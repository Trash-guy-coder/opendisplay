import Foundation
import Combine

/// Each device owns its UI language. Changing it does not rebuild a receiver,
/// reconnect a stream, or alter the English protocol/status identifiers.
final class AppLanguage: ObservableObject {
    static let shared = AppLanguage()
    @Published var selection: String {
        didSet { UserDefaults.standard.set(selection, forKey: "uiLanguage") }
    }
    private init() {
        let saved = UserDefaults.standard.string(forKey: "uiLanguage") ?? "system"
        selection = ["system", "en", "zh-Hans"].contains(saved) ? saved : "system"
    }
    var locale: Locale { selection == "system" ? .current : Locale(identifier: selection) }

    static func bundle(for selection: String, in base: Bundle = .main) -> Bundle {
        guard ["en", "zh-Hans"].contains(selection),
              let path = base.path(forResource: selection, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return base }
        return bundle
    }
    static var bundle: Bundle {
        bundle(for: UserDefaults.standard.string(forKey: "uiLanguage") ?? "system")
    }
    static func text(_ key: String, table: String = "FeatureStrings") -> String {
        bundle.localizedString(forKey: key, value: key, table: table)
    }
}
