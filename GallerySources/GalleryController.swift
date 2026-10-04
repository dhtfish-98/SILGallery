// Restructured derivative of Alex Blewitt / Bandlem Ltd., 2015. MIT notices in 项目文档/LICENSE.md.
import Foundation
import Cocoa

@NSApplicationMain
class GalleryController: NSObject, NSApplicationDelegate, NSTabViewDelegate {
    @IBOutlet weak var galleryWindow: NSWindow!
    @IBOutlet weak var galleryTabs: NSTabView!
    @IBOutlet weak var galleryCommandText: NSTextField!
    @IBOutlet weak var gallerySourcePane: NSScrollView!
    @IBOutlet weak var galleryRawPane: NSScrollView!
    @IBOutlet weak var galleryCanonicalPane: NSScrollView!
    @IBOutlet weak var galleryAssemblyPane: NSScrollView!
    @IBOutlet weak var galleryIRPane: NSScrollView!
    @IBOutlet weak var galleryASTPane: NSScrollView!
    @IBOutlet weak var galleryParsePane: NSScrollView!
    var galleryDemangling = false
    var galleryOptimization = false
    var galleryWholeModule = false
    var galleryLibrary = false

    func galleryText(_ pane: NSScrollView?) -> NSTextView? {
        pane?.documentView as? NSTextView
    }
    private func galleryRead(_ pane: NSScrollView?) -> String {
        guard let text = galleryText(pane) else {
            galleryCommandText?.stringValue = "A text view is unavailable."
            return ""
        }
        return text.string
    }
    private func galleryWrite(_ value: String, to pane: NSScrollView?) {
        guard let text = galleryText(pane) else {
            galleryCommandText?.stringValue = "A text view is unavailable."
            return
        }
        text.string = value
    }
    var gallerySource: String {
        get { galleryRead(gallerySourcePane) }
        set { galleryWrite(newValue, to: gallerySourcePane) }
    }
    var galleryRaw: String {
        get { galleryRead(galleryRawPane) }
        set { galleryWrite(newValue, to: galleryRawPane) }
    }
    var galleryCanonical: String {
        get { galleryRead(galleryCanonicalPane) }
        set { galleryWrite(newValue, to: galleryCanonicalPane) }
    }
    var galleryParse: String {
        get { galleryRead(galleryParsePane) }
        set { galleryWrite(newValue, to: galleryParsePane) }
    }
    var galleryAST: String {
        get { galleryRead(galleryASTPane) }
        set { galleryWrite(newValue, to: galleryASTPane) }
    }
    var galleryAssembly: String {
        get { galleryRead(galleryAssemblyPane) }
        set { galleryWrite(newValue, to: galleryAssemblyPane) }
    }
    var galleryIR: String {
        get { galleryRead(galleryIRPane) }
        set { galleryWrite(newValue, to: galleryIRPane) }
    }
}
