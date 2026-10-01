import XCTest
@testable import SILGallery
final class GalleryFixtureTests: XCTestCase {
    func testGalleryLibraryModuleIdentity() {
        let galleryPlan = GalleryCommandPlan(galleryLibrary: true, galleryWholeModule: true, galleryOptimization: true, galleryDemangling: true)
        XCTAssertEqual(galleryPlan.galleryCompose("swiftc - -emit-sil"), "swiftc - -emit-sil -parse-as-library -module-name SILInspector -whole-module-optimization -O | xcrun swift-demangle")
    }
}
