import Foundation

/// Read-only inventory of existing Mac displays, shared with the iPad picker.
struct MirrorDisplaySource: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let pointWidth: Int
    let pointHeight: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let isMain: Bool

    var isValid: Bool {
        UUID(uuidString: id) != nil && !name.isEmpty && name.count <= 64
            && [pointWidth, pointHeight, pixelWidth, pixelHeight].allSatisfy { (1...16384).contains($0) }
    }
    var label: String {
        "\(name) · \(pointWidth) × \(pointHeight)"
            + (pixelWidth > pointWidth ? " HiDPI" : "")
    }
}
