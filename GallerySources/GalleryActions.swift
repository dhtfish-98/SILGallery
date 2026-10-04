// UI connections and Cocoa protocol callbacks. See ORIGIN.md.
import Cocoa

extension GalleryController {
    @IBAction func galleryChangeFontSize(_ gallerySender: NSSlider) {
        galleryApplyFontSize(gallerySender.integerValue)
    }
    @IBAction func galleryToggleDemangling(_ gallerySender: NSButton) {
        galleryDemangling = gallerySender.state != NSControl.StateValue.off
        if let tabs = galleryTabs { tabView(tabs, willSelect: tabs.selectedTabViewItem) }
    }
    @IBAction func galleryToggleLibrary(_ gallerySender: NSButton) {
        galleryLibrary = gallerySender.state != NSControl.StateValue.off
        if let tabs = galleryTabs { tabView(tabs, willSelect: tabs.selectedTabViewItem) }
    }
    @IBAction func galleryToggleOptimization(_ gallerySender: NSButton) {
        galleryOptimization = gallerySender.state != NSControl.StateValue.off
        if let tabs = galleryTabs { tabView(tabs, willSelect: tabs.selectedTabViewItem) }
    }
    @IBAction func galleryToggleWholeModule(_ gallerySender: NSButton) {
        galleryWholeModule = gallerySender.state != NSControl.StateValue.off
        if let tabs = galleryTabs { tabView(tabs, willSelect: tabs.selectedTabViewItem) }
    }
    func galleryApplyFontSize(_ gallerySize: Int) {
        guard (8...48).contains(gallerySize) else {
            galleryCommandText?.stringValue = "Font size must be between 8 and 48."
            return
        }
        let galleryFont = NSFontManager.shared.font(withFamily: "Monaco", traits: .unboldFontMask,
                                                  weight: 0, size: CGFloat(gallerySize))
        for galleryScroll in [gallerySourcePane, galleryASTPane, galleryParsePane, galleryRawPane,
                              galleryCanonicalPane, galleryIRPane, galleryAssemblyPane] {
            galleryText(galleryScroll)?.font = galleryFont
        }
    }
    func applicationDidFinishLaunching(_ galleryNotification: Notification) {
        galleryApplyFontSize(18)
        guard let source = galleryText(gallerySourcePane) else {
            galleryCommandText?.stringValue = "Source text view is unavailable."
            return
        }
        source.isAutomaticQuoteSubstitutionEnabled = false
        source.isAutomaticDashSubstitutionEnabled = false
        source.isAutomaticTextReplacementEnabled = false
        source.isAutomaticSpellingCorrectionEnabled = false
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
        default: galleryCommandText?.stringValue = ""
        }
    }
}
