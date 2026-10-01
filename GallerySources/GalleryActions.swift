// UI connections and Cocoa protocol callbacks. See ORIGIN.md.
import Cocoa

extension GalleryController {
    @IBAction func galleryChangeFontSize(_ gallerySender: NSSlider) {
        galleryApplyFontSize(gallerySender.integerValue)
    }
    @IBAction func galleryToggleDemangling(_ gallerySender: NSButton) {
        galleryDemangling = gallerySender.state != NSControl.StateValue.off
        tabView(galleryTabs, willSelect: galleryTabs.selectedTabViewItem)
    }
    @IBAction func galleryToggleLibrary(_ gallerySender: NSButton) {
        galleryLibrary = gallerySender.state != NSControl.StateValue.off
        tabView(galleryTabs, willSelect: galleryTabs.selectedTabViewItem)
    }
    @IBAction func galleryToggleOptimization(_ gallerySender: NSButton) {
        galleryOptimization = gallerySender.state != NSControl.StateValue.off
        tabView(galleryTabs, willSelect: galleryTabs.selectedTabViewItem)
    }
    @IBAction func galleryToggleWholeModule(_ gallerySender: NSButton) {
        galleryWholeModule = gallerySender.state != NSControl.StateValue.off
        tabView(galleryTabs, willSelect: galleryTabs.selectedTabViewItem)
    }
    func galleryApplyFontSize(_ gallerySize: Int) {
        let galleryFont = NSFontManager.shared.font(withFamily: "Monaco", traits: .unboldFontMask,
                                                  weight: 0, size: CGFloat(gallerySize))
        for galleryScroll in [gallerySourcePane, galleryASTPane, galleryParsePane, galleryRawPane,
                              galleryCanonicalPane, galleryIRPane, galleryAssemblyPane] {
            let galleryText = galleryScroll?.documentView as! NSTextView
            galleryText.font = galleryFont
        }
    }
    func applicationDidFinishLaunching(_ galleryNotification: Notification) {
        galleryApplyFontSize(18)
        let galleryText = gallerySourcePane.documentView as! NSTextView
        galleryText.isAutomaticQuoteSubstitutionEnabled = false
        galleryText.isAutomaticDashSubstitutionEnabled = false
        galleryText.isAutomaticTextReplacementEnabled = false
        galleryText.isAutomaticSpellingCorrectionEnabled = false
    }
    func applicationWillTerminate(_ galleryNotification: Notification) {}
    func tabView(_ gallerySelectedTabs: NSTabView, willSelect galleryTabItem: NSTabViewItem?) {
        let galleryTitle = galleryTabItem?.label
        switch galleryTitle {
        case .some("SIL Raw"): galleryUpdateRaw()
        case .some("SIL Canonical"): galleryUpdateCanonical()
        case .some("AST"): galleryUpdateAST()
        case .some("Parse"): galleryUpdateParse()
        case .some("IR"): galleryUpdateIR()
        case .some("Assembly"): galleryUpdateAssembly()
        default: galleryCommandText.stringValue = ""
        }
    }
}
