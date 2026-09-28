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

    func testQHDAndUHDHaveRealPixelDimensionsAndReadableHiDPICanvases() throws {
        XCTAssertEqual(DesktopResolution.qhd.pixels(nativeWidth: 2388, nativeHeight: 1668), PixelSize(width: 2560, height: 1440))
        XCTAssertEqual(DesktopResolution.uhd.pixels(nativeWidth: 1668, nativeHeight: 2388), PixelSize(width: 2160, height: 3840))
        let plan = try XCTUnwrap(VirtualCanvasSizing.plan(pixelsWide: 3840, pixelsHigh: 2160,
                                                          pixelsPerPoint: DesktopResolution.uhd.pixelsPerPoint))
        XCTAssertEqual(plan.requested.pointsWide, 1920)
        XCTAssertEqual(plan.requested.pointsHigh, 1080)
        XCTAssertEqual(plan.requested.pixelsWide, 3840)
        XCTAssertEqual(plan.bootstrap.pixelsWide, 3200)
        XCTAssertEqual(DesktopResolution.fullHD.pixelsPerPoint, 1)
    }

    func testMirrorNeverUpscalesOrDistortsThePhysicalSource() {
        XCTAssertEqual(DesktopResolution.uhd.mirrorPixels(source: PixelSize(width: 1920, height: 1080)),
                       PixelSize(width: 1920, height: 1080))
        XCTAssertEqual(DesktopResolution.qhd.mirrorPixels(source: PixelSize(width: 3840, height: 2160)),
                       PixelSize(width: 2560, height: 1440))
        XCTAssertEqual(DesktopResolution.fullHD.mirrorPixels(source: PixelSize(width: 2048, height: 1536)),
                       PixelSize(width: 1440, height: 1080))
        XCTAssertEqual(DesktopResolution.qhd.mirrorPixels(source: PixelSize(width: 2160, height: 3840)),
                       PixelSize(width: 1440, height: 2560))
    }

    func testUltraBitrateUsesNegotiatedSizeAndFrameRateAndStaysBounded() throws {
        let fourK = try H264StreamConfiguration.make(source: PixelSize(width: 3840, height: 2160), quality: .ultra,
                                                     requestedFramesPerSecond: 120)
        XCTAssertEqual(fourK.encodedSize, PixelSize(width: 3840, height: 2160))
        XCTAssertEqual(fourK.framesPerSecond, 63)
        XCTAssertEqual(fourK.bitrate, 80_000_000)
        let qhd = try H264StreamConfiguration.make(source: PixelSize(width: 2560, height: 1440), quality: .ultra)
        XCTAssertEqual(qhd.bitrate, 45_000_000)
        let limited = try H264StreamConfiguration.make(source: PixelSize(width: 3840, height: 2160), quality: .ultra,
            receiverCapabilities: [VideoCapability(codec: "h264", maxWidth: 1920, maxHeight: 1080, maxFrameRate: 30)])
        XCTAssertEqual(limited.encodedSize, PixelSize(width: 1920, height: 1080))
        XCTAssertEqual(limited.framesPerSecond, 30)
        XCTAssertEqual(limited.bitrate, 24_000_000)
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
