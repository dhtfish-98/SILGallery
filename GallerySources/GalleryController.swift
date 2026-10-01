// Restructured derivative of Alex Blewitt / Bandlem Ltd., 2015. MIT notices in LICENSE.md.
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

    var gallerySource: String {
        get { (gallerySourcePane.documentView as! NSTextView).string }
        set { (gallerySourcePane.documentView as! NSTextView).string = newValue }
    }
    var galleryRaw: String {
        get { (galleryRawPane.documentView as! NSTextView).string }
        set { (galleryRawPane.documentView as! NSTextView).string = newValue }
    }
    var galleryCanonical: String {
        get { (galleryCanonicalPane.documentView as! NSTextView).string }
        set { (galleryCanonicalPane.documentView as! NSTextView).string = newValue }
    }
    var galleryParse: String {
        get { (galleryParsePane.documentView as! NSTextView).string }
        set { (galleryParsePane.documentView as! NSTextView).string = newValue }
    }
    var galleryAST: String {
        get { (galleryASTPane.documentView as! NSTextView).string }
        set { (galleryASTPane.documentView as! NSTextView).string = newValue }
    }
    var galleryAssembly: String {
        get { (galleryAssemblyPane.documentView as! NSTextView).string }
        set { (galleryAssemblyPane.documentView as! NSTextView).string = newValue }
    }
    var galleryIR: String {
        get { (galleryIRPane.documentView as! NSTextView).string }
        set { (galleryIRPane.documentView as! NSTextView).string = newValue }
    }
}
