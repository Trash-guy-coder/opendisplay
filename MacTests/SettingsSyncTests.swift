import XCTest

final class SettingsSyncTests: XCTestCase {
    func testReceiverPatchesRoundTripWithoutOverwritingOtherSettings() throws {
        let current = ReceiverSettings(inputEnabled: true, swapCommandAndOption: true,
            pointerSpeed: 1.25, scrollSpeed: 0.5, reverseScroll: false,
            showAnalytics: false, metalRenderer: false, deviceName: "iPad")
        let json = try XCTUnwrap(SettingsSync.json(ReceiverSettings(pointerSpeed: 1.5), type: SettingsSync.receiverChange))
        let patch = try XCTUnwrap(SettingsSync.decode(ReceiverSettings.self, data: Data(json.utf8), message: SettingsSync.receiverChange))
        let updated = current.merging(patch)
        XCTAssertEqual(updated.pointerSpeed, 1.5)
        XCTAssertEqual(updated.swapCommandAndOption, true)
        XCTAssertEqual(updated.scrollSpeed, 0.5)
        XCTAssertEqual(updated.deviceName, "iPad")
        XCTAssertTrue(updated.isComplete)
        XCTAssertFalse(patch.isComplete)
    }

    func testMalformedWrongVersionAndOversizeMessagesAreRejected() {
        for json in [
            #"{"type":"setReceiverSettings","settingsVersion":4,"values":{"pointerSpeed":1.5}}"#,
            #"{"type":"setReceiverSettings","settingsVersion":3,"values":{"inputEnabled":"true"}}"#,
            #"{"type":"setReceiverSettings","settingsVersion":3,"values":{"pointerSpeed":true}}"#,
            #"{"type":"receiverSettings","settingsVersion":3,"values":{"pointerSpeed":1.5}}"#
        ] {
            XCTAssertNil(SettingsSync.decode(ReceiverSettings.self, data: Data(json.utf8), message: SettingsSync.receiverChange))
        }
        XCTAssertNil(SettingsSync.decode(ReceiverSettings.self, data: Data(repeating: 32, count: 4097), message: SettingsSync.receiverChange))
        XCTAssertFalse(ReceiverSettings().isValidPatch)
        XCTAssertFalse(ReceiverSettings(pointerSpeed: .nan).isValidPatch)
        XCTAssertFalse(ReceiverSettings(scrollSpeed: 5).isValidPatch)
        XCTAssertFalse(ReceiverSettings(deviceName: "  ").isValidPatch)
        XCTAssertFalse(ReceiverSettings(deviceName: String(repeating: "x", count: 121)).isValidPatch)
    }

    func testInvalidPatchCannotPartiallyWritePreferencesAndFalseIsNotMissing() throws {
        let suite = "OpenDisplay.SettingsSyncTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        ReceiverSettings(inputEnabled: false, pointerSpeed: 1.5).apply(to: defaults)
        ReceiverSettings(inputEnabled: true, scrollSpeed: 100).apply(to: defaults)
        let result = ReceiverSettings.read(from: defaults, fallbackName: "iPad")
        XCTAssertEqual(result.inputEnabled, false)
        XCTAssertEqual(result.pointerSpeed, 1.5)
        XCTAssertEqual(result.scrollSpeed, 0.5)
        XCTAssertTrue(result.isComplete)
    }

    func testSenderSettingsValidateAllSupportedPresetsAndRejectUnknownValues() {
        for quality in StreamQuality.allCases {
            for resolution in DesktopResolution.allCases {
                for rate in DisplayRefreshRate.allCases {
                    XCTAssertTrue(SenderSettings(mode: "mirror", resolution: resolution.rawValue,
                        refreshRate: rate.rawValue, quality: quality.rawValue, lowLatencyCursor: true, customWidth: 2560, customHeight: 1600).isComplete)
                }
            }
        }
        XCTAssertFalse(SenderSettings(mode: "invalid").isValid)
        XCTAssertFalse(SenderSettings(refreshRate: 1000).isValid)
        XCTAssertFalse(SenderSettings(quality: "unknown").isValid)
        XCTAssertTrue(SenderSettings(lowLatencyCursor: false).isValid)
        XCTAssertFalse(SenderSettings(lowLatencyCursor: false).isComplete)
    }

    func testExplicitLanguageBundlesOverrideSystemAndKeepEnglishAvailable() throws {
        let resources = Bundle(for: Self.self)
        let chinese = AppLanguage.bundle(for: "zh-Hans", in: resources)
        let english = AppLanguage.bundle(for: "en", in: resources)
        XCTAssertEqual(chinese.localizedString(forKey: "Swap Command and Option", value: nil, table: "FeatureStrings"), "交换 Command 与 Option")
        XCTAssertEqual(english.localizedString(forKey: "Swap Command and Option", value: nil, table: "FeatureStrings"), "Swap Command and Option")
        XCTAssertEqual(chinese.localizedString(forKey: "Interface language", value: nil, table: "FeatureStrings"), "界面语言")
        XCTAssertTrue(AppLanguage.bundle(for: "system", in: resources) === resources)
    }
}
