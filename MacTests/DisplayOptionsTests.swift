import XCTest
import CoreGraphics

final class DisplayOptionsTests: XCTestCase {
    func testPresetOrientationAndNativePanelArePreserved() {
        XCTAssertEqual(DesktopResolution.native.pixels(nativeWidth: 2388, nativeHeight: 1668), PixelSize(width: 2388, height: 1668))
        XCTAssertEqual(DesktopResolution.fullHD.pixels(nativeWidth: 2388, nativeHeight: 1668), PixelSize(width: 1920, height: 1080))
        XCTAssertEqual(DesktopResolution.hd.pixels(nativeWidth: 1668, nativeHeight: 2388), PixelSize(width: 720, height: 1280))
    }

    func testMirrorSelectsMainInsteadOfFirstVirtualDisplay() {
        XCTAssertEqual(MirrorDisplaySelection.select(available: [21, 5, 1], main: 1), 1)
        XCTAssertNil(MirrorDisplaySelection.select(available: [21, 5], main: 1))
    }

    func testHighRefreshFallsBackToReceiverCeiling() throws {
        let limited = try H264StreamConfiguration.make(source: PixelSize(width: 1920, height: 1080), quality: .best, receiverCapabilities: [VideoCapability(codec: "h264", maxFrameRate: 60)], displayMaxFrameRate: 120, requestedFramesPerSecond: 120)
        XCTAssertEqual(limited.framesPerSecond, 60)
        let high = try H264StreamConfiguration.make(source: PixelSize(width: 1920, height: 1080), quality: .best, receiverCapabilities: [VideoCapability(codec: "h264", maxFrameRate: 120)], displayMaxFrameRate: 120, requestedFramesPerSecond: 120)
        XCTAssertEqual(high.framesPerSecond, 120)
        let physical = try H264StreamConfiguration.make(source: PixelSize(width: 1280, height: 720), quality: .best, displayMaxFrameRate: 60, requestedFramesPerSecond: 90)
        XCTAssertEqual(physical.framesPerSecond, 60)
    }

}
