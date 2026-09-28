import XCTest

final class ResolutionPresetTests: XCTestCase {
    func testIPadPresetsKeepPhysicalPixelsAndRotateWithoutChangingAspect() throws {
        let presets: [(ResolutionPreset, Int, Int)] = [
            (.ipad102, 2160, 1620), (.ipadA16, 2360, 1640), (.air11, 2360, 1640),
            (.air13, 2732, 2048), (.pro11, 2388, 1668), (.pro11OLED, 2420, 1668),
            (.pro129, 2732, 2048), (.pro13OLED, 2752, 2064)
        ]
        for (preset, width, height) in presets {
            XCTAssertEqual(preset.pixels(nativeWidth: 2388, nativeHeight: 1668), PixelSize(width: width, height: height))
            XCTAssertEqual(preset.pixels(nativeWidth: 1668, nativeHeight: 2388), PixelSize(width: height, height: width))
            let canvas = try XCTUnwrap(VirtualCanvasSizing.requested(pixelsWide: width, pixelsHigh: height,
                                                                     pixelsPerPoint: preset.pixelsPerPoint))
            XCTAssertEqual(canvas.pixelsWide, width)
            XCTAssertEqual(canvas.pixelsHigh, height)
        }
    }

    func testCustomSizeIsExactAndFollowsReceiverOrientation() {
        let custom = CustomResolution(width: 2560, height: 1600)
        XCTAssertEqual(DesktopResolution.custom.pixels(nativeWidth: 2388, nativeHeight: 1668, custom: custom),
                       PixelSize(width: 2560, height: 1600))
        XCTAssertEqual(DesktopResolution.custom.pixels(nativeWidth: 1668, nativeHeight: 2388, custom: custom),
                       PixelSize(width: 1600, height: 2560))
        XCTAssertEqual(DesktopResolution.custom.pixels(nativeWidth: 2388, nativeHeight: 1668,
            custom: .init(width: 1600, height: 2560)), PixelSize(width: 2560, height: 1600))
        XCTAssertEqual(DesktopResolution.custom.mirrorPixels(source: PixelSize(width: 1920, height: 1080), custom: custom),
                       PixelSize(width: 1920, height: 1080))
    }

    func testCustomValidationRejectsPartialOutOfRangeAndMisalignedRequests() {
        XCTAssertNotNil(CustomResolution.parse(width: " 2388 ", height: "1668"))
        for pair in [("319", "1600"), ("8196", "1600"), ("2562", "1600"), ("2560", ""), ("abc", "1600"), ("999999999999999999999999", "1600")] {
            XCTAssertNil(CustomResolution.parse(width: pair.0, height: pair.1))
        }
        XCTAssertFalse(SenderSettings(resolution: "custom").isValid)
        XCTAssertFalse(SenderSettings(customWidth: 2560).isValid)
        XCTAssertFalse(SenderSettings(customWidth: 2560, customHeight: 100).isValid)
        XCTAssertTrue(SenderSettings(resolution: "custom", customWidth: 2388, customHeight: 1668).isValid)
        XCTAssertFalse(SenderSettings(nativeWidth: 2388, nativeHeight: 1668).isValid)
    }

    func testNativeSnapshotAndCustomPatchRoundTripAndEncoderLimitsStillApply() throws {
        let state = SenderSettings(mode: "extend", resolution: "custom", refreshRate: 120, quality: "ultra",
            lowLatencyCursor: true, customWidth: 8192, customHeight: 8192, nativeWidth: 2388, nativeHeight: 1668)
        XCTAssertTrue(state.isComplete)
        let json = try XCTUnwrap(SettingsSync.json(state, type: SettingsSync.senderState))
        let decoded = try XCTUnwrap(SettingsSync.decode(SenderSettings.self, data: Data(json.utf8), message: SettingsSync.senderState))
        XCTAssertEqual(decoded, state)
        let config = try H264StreamConfiguration.make(source: PixelSize(width: 8192, height: 8192), quality: .ultra,
            receiverCapabilities: [VideoCapability(codec: "h264", maxWidth: 3840, maxHeight: 2160, maxFrameRate: 60)])
        XCTAssertLessThanOrEqual(config.encodedSize.width, 3840)
        XCTAssertLessThanOrEqual(config.encodedSize.height, 2160)
        XCTAssertLessThanOrEqual(config.framesPerSecond, 60)
    }
}
