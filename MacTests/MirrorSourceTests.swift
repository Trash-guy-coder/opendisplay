import XCTest

final class MirrorSourceTests: XCTestCase {
    private let physical = "00000000-0000-0000-0000-000000000001"
    private let virtual = "00000000-0000-0000-0000-000000000002"

    func testExplicitVirtualSourceWinsOverPhysicalMain() {
        let ids: [UInt32: String] = [1: physical, 5: virtual]
        XCTAssertEqual(MirrorDisplaySelection.select(available: [1, 5], main: 1,
            preference: virtual, uuidByID: ids), 5)
        XCTAssertEqual(MirrorDisplaySelection.select(available: [1, 5], main: 1,
            preference: physical, uuidByID: ids), 1)
        XCTAssertEqual(MirrorDisplaySelection.select(available: [1, 5], main: 1), 1)
    }

    func testMissingChosenDisplayNeverFallsBackToPhysicalScreen() {
        XCTAssertNil(MirrorDisplaySelection.select(available: [1], main: 1,
            preference: virtual, uuidByID: [1: physical]))
        XCTAssertEqual(MirrorDisplaySelection.select(available: [1, 41], main: 1,
            preference: virtual, uuidByID: [1: physical, 41: virtual]), 41)
    }

    func testDisplayMetadataAndSourceChangeRoundTripWithoutChangingModeOrResolution() throws {
        let display = MirrorDisplaySource(id: virtual, name: "Virtual display",
            pointWidth: 1194, pointHeight: 834, pixelWidth: 2388, pixelHeight: 1668, isMain: false)
        XCTAssertTrue(display.isValid)
        XCTAssertTrue(display.label.contains("1194 × 834 HiDPI"))
        let patch = SenderSettings(mirrorDisplayID: virtual)
        XCTAssertTrue(patch.isValid)
        XCTAssertNil(patch.mode)
        XCTAssertNil(patch.resolution)
        let json = try XCTUnwrap(SettingsSync.json(patch, type: SettingsSync.senderChange))
        XCTAssertEqual(SettingsSync.decode(SenderSettings.self, data: Data(json.utf8), message: SettingsSync.senderChange), patch)
        XCTAssertFalse(SenderSettings(mirrorDisplayID: "arbitrary path").isValid)
        XCTAssertFalse(SenderSettings(availableMirrorDisplays: [display]).isValid)
    }
}
