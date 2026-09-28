import XCTest

final class FeatureLocalizationTests: XCTestCase {
    private func languageBundle(_ language: String) throws -> Bundle {
        let resources = Bundle(for: Self.self)
        let path = try XCTUnwrap(resources.path(forResource: language, ofType: "lproj"))
        return try XCTUnwrap(Bundle(path: path))
    }
    func testEnglishAndChineseControlsAreAvailableInCompiledCatalog() throws {
        let english = try languageBundle("en")
        let chinese = try languageBundle("zh-Hans")
        XCTAssertEqual(english.localizedString(forKey: "Pointer speed", value: nil, table: "FeatureStrings"), "Pointer speed")
        XCTAssertEqual(chinese.localizedString(forKey: "Mac shortcut mode", value: nil, table: "FeatureStrings"), "Mac 快捷键模式")
        XCTAssertEqual(chinese.localizedString(forKey: "Pointer speed", value: nil, table: "FeatureStrings"), "指针速度")
        XCTAssertEqual(chinese.localizedString(forKey: "Reverse scroll direction", value: nil, table: "FeatureStrings"), "反转滚动方向")
    }
    func testLocalizedStreamStatusPreservesDeviceDimensionsAndTargetRate() throws {
        let english = try languageBundle("en")
        let chinese = try languageBundle("zh-Hans")
        let status = "Mirroring to iPad (1920×1080, 120 fps target)"
        XCTAssertEqual(FeatureLocalization.streamStatus(status, bundle: english), status)
        XCTAssertEqual(FeatureLocalization.streamStatus(status, bundle: chinese), "正在镜像到 iPad（1920×1080，目标 120 fps）")
        XCTAssertEqual(FeatureLocalization.streamStatus("Extending to device (1280×720, 60 fps target)", bundle: chinese), "正在扩展到 设备（1280×720，目标 60 fps）")
        XCTAssertNil(FeatureLocalization.streamStatus("Connection lost — retrying for 10s…", bundle: chinese))
    }
}
