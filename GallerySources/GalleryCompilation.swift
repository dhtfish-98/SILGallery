// Compiler command composition and process exchange. See ORIGIN.md.
import Foundation
import Cocoa

struct GalleryCommandPlan {
    var galleryLibrary: Bool
    var galleryWholeModule: Bool
    var galleryOptimization: Bool
    var galleryDemangling: Bool
    func galleryCompose(_ galleryProgram: String) -> String {
        var galleryCommand = galleryProgram
        // Preserve the emitted module identity as compatibility data for SIL/IR output.
        if galleryLibrary { galleryCommand += " -parse-as-library -module-name SILInspector" }
        if galleryWholeModule { galleryCommand += " -whole-module-optimization" }
        if galleryOptimization { galleryCommand += " -O" }
        if galleryDemangling { galleryCommand += " | xcrun swift-demangle" }
        return galleryCommand
    }
}

extension GalleryController {
    func galleryUpdateRaw() { galleryRaw = galleryRunCommand("swiftc - -emit-silgen") }
    func galleryUpdateCanonical() { galleryCanonical = galleryRunCommand("swiftc - -emit-sil") }
    func galleryUpdateAST() { galleryAST = galleryRunCommand("swiftc - -dump-ast") }
    func galleryUpdateParse() { galleryParse = galleryRunCommand("swiftc - -dump-parse") }
    func galleryUpdateIR() { galleryIR = galleryRunCommand("swiftc - -emit-ir") }
    func galleryUpdateAssembly() { galleryAssembly = galleryRunCommand("swiftc - -emit-assembly") }

    func galleryRunCommand(_ galleryProgram: String) -> String {
        let galleryPlan = GalleryCommandPlan(galleryLibrary: galleryLibrary, galleryWholeModule: galleryWholeModule,
                                             galleryOptimization: galleryOptimization, galleryDemangling: galleryDemangling)
        let galleryCommand = galleryPlan.galleryCompose(galleryProgram)
        galleryCommandText.stringValue = galleryCommand
        let galleryInputPipe = Pipe()
        let galleryInputHandle = galleryInputPipe.fileHandleForWriting
        galleryInputHandle.write(gallerySource.data(using: .utf8)!)
        galleryInputHandle.closeFile()
        let galleryProcess = Process()
        galleryProcess.launchPath = "/bin/bash"
        galleryProcess.arguments = ["-c", galleryCommand]
        let galleryErrorPipe = Pipe()
        let galleryOutputPipe = Pipe()
        galleryProcess.standardInput = galleryInputPipe
        galleryProcess.standardOutput = galleryOutputPipe
        galleryProcess.standardError = galleryErrorPipe
        galleryProcess.launch()
        let galleryOutputBytes = galleryOutputPipe.fileHandleForReading.readDataToEndOfFile()
        let galleryErrorBytes = galleryErrorPipe.fileHandleForReading.readDataToEndOfFile()
        let galleryOutput = String(data: galleryOutputBytes, encoding: .utf8)!
        let galleryError = String(data: galleryErrorBytes, encoding: .utf8)!
        return galleryError == "" || galleryError == "\n" ? galleryOutput : galleryError
    }
}
