import XCTest

final class ReceiverLocalizationTests: XCTestCase {
    private func language(_ name: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle(for: Self.self).path(forResource: name, ofType: "lproj"))
        return try XCTUnwrap(Bundle(path: path))
    }

    func testSettingsTitlesAndRuntimeValuesUseChineseCatalog() throws {
        let chinese = try language("zh-Hans")
        for (key, expected) in [("Settings & Help", "设置与帮助"), ("Status", "状态"),
                                ("Listening", "监听端口"), ("Connected", "已连接"),
                                ("Waiting for Mac", "等待 Mac 连接"), ("Device name", "设备名称"),
                                ("Performance overlay", "显示性能信息"), ("Done", "完成")] {
            XCTAssertEqual(ReceiverLocalization.text(key, bundle: chinese), expected)
        }
    }

    func testConnectionStatusPreservesDimensionsAndDiagnosticDetails() throws {
        let chinese = try language("zh-Hans")
        XCTAssertEqual(ReceiverLocalization.status("Receiving 1920×1080", bundle: chinese), "正在接收 1920×1080")
        XCTAssertEqual(ReceiverLocalization.status("Listening on :9000", bundle: chinese), "正在监听端口 9000")
        XCTAssertEqual(ReceiverLocalization.status("Listener failed: error 48", bundle: chinese), "监听失败：error 48")
        XCTAssertEqual(ReceiverLocalization.status("New unknown status", bundle: chinese), "New unknown status")
    }

    func testEnglishFallbackAndDeviceNamePlaceholders() throws {
        let english = try language("en")
        let chinese = try language("zh-Hans")
        XCTAssertEqual(ReceiverLocalization.status("Receiving 1920×1080", bundle: english), "Receiving 1920×1080")
        XCTAssertEqual(ReceiverLocalization.format("Or choose this %@ under WiFi in the Mac app", "iPad", bundle: chinese),
                       "或在 Mac 应用的 WiFi 菜单中选择这台 iPad")
        XCTAssertEqual(ReceiverLocalization.format("(showing the last %d lines, the shared file has all of them)", 400, bundle: chinese),
                       "（当前显示最后 400 行，分享的文件包含完整日志）")
    }
}
