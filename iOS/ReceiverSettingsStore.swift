import UIKit
import Combine

@MainActor
final class ReceiverSettingsStore: ObservableObject {
    static let shared = ReceiverSettingsStore()
    @Published private(set) var values: ReceiverSettings
    private var observer: NSObjectProtocol?
    private init() {
        values = ReceiverSettings.read(fallbackName: UIDevice.current.name)
        observer = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification,
                                                          object: UserDefaults.standard, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
    }
    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    func apply(_ patch: ReceiverSettings) {
        guard patch.isValidPatch else { return }
        patch.apply()
        reload()
    }
    private func reload() {
        let updated = ReceiverSettings.read(fallbackName: UIDevice.current.name)
        if updated != values { values = updated }
    }
}
