import XCTest

final class DisplayLocalizationTests: XCTestCase {
    private func languageBundle(_ language: String) throws -> Bundle {
        let resources = Bundle(for: Self.self)
        let path = try XCTUnwrap(resources.path(forResource: language, ofType: "lproj"))
        return try XCTUnwrap(Bundle(path: path))
    }
    func testEnglishAndChineseControlsAreAvailableInCompiledCatalog() throws {
        let english = try languageBundle("en")
        let chinese = try languageBundle("zh-Hans")
        XCTAssertEqual(english.localizedString(forKey: "Resolution", value: nil, table: "DisplayStrings"), "Resolution")
        XCTAssertEqual(chinese.localizedString(forKey: "Resolution", value: nil, table: "DisplayStrings"), "分辨率")
        XCTAssertEqual(chinese.localizedString(forKey: "Frame-rate limit", value: nil, table: "DisplayStrings"), "刷新率上限")
    }
    func testLocalizedStreamStatusPreservesDeviceDimensionsAndTargetRate() throws {
        let english = try languageBundle("en")
        let chinese = try languageBundle("zh-Hans")
        let status = "Mirroring to iPad (1920×1080, 120 fps target)"
        XCTAssertEqual(DisplayLocalization.streamStatus(status, bundle: english), status)
        XCTAssertEqual(DisplayLocalization.streamStatus(status, bundle: chinese), "正在镜像到 iPad（1920×1080，目标 120 fps）")
        XCTAssertEqual(DisplayLocalization.streamStatus("Extending to device (1280×720, 60 fps target)", bundle: chinese), "正在扩展到 设备（1280×720，目标 60 fps）")
        XCTAssertNil(DisplayLocalization.streamStatus("Connection lost — retrying for 10s…", bundle: chinese))
    }
}
