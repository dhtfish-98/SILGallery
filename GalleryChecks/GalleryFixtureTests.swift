import XCTest
@testable import SILGallery
final class GalleryFixtureTests: XCTestCase {
    func testGalleryLibraryModuleIdentity() {
        let galleryPlan = GalleryCommandPlan(galleryLibrary: true, galleryWholeModule: true, galleryOptimization: true, galleryDemangling: true)
        XCTAssertEqual(galleryPlan.galleryCompose("swiftc - -emit-sil"), "swiftc - -emit-sil -parse-as-library -module-name SILInspector -whole-module-optimization -O | xcrun swift-demangle")
    }
    func testMissingOrMismatchedTextViewsDoNotCrash() {
        let controller = GalleryController()
        let status = NSTextField()
        controller.galleryCommandText = status
        XCTAssertEqual(controller.galleryRunCommand("swiftc - -emit-sil"), "Source text view is unavailable.")
        XCTAssertEqual(status.stringValue, "Source text view is unavailable.")

        let wrongSource = NSScrollView()
        wrongSource.documentView = NSView()
        controller.gallerySourcePane = wrongSource
        XCTAssertEqual(controller.galleryRunCommand("swiftc - -emit-sil"), "Source text view is unavailable.")
        XCTAssertEqual(status.stringValue, "Source text view is unavailable.")

        let sourcePane = NSScrollView()
        let source = NSTextView()
        sourcePane.documentView = source
        controller.gallerySourcePane = sourcePane
        controller.galleryUpdateRaw()
        XCTAssertEqual(status.stringValue, "Output text view is unavailable.")

        controller.galleryApplyFontSize(18)
        let originalFont = source.font
        controller.galleryApplyFontSize(49)
        XCTAssertEqual(source.font, originalFont)
        XCTAssertEqual(status.stringValue, "Font size must be between 8 and 48.")
    }
}
