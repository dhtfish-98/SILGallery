// Compiler command composition and process exchange. See ORIGIN.md.
import Foundation
import Cocoa
import Darwin

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

// Temporary files avoid deadlocks from writing stdin before launch or draining
// stdout and stderr sequentially. Only the caller's fixed compiler modes are exposed.
struct GalleryProcessOutput {
    let stdout: String
    let stderr: String
    let status: Int32
}

struct GalleryProcessExchange {
    static func galleryFailure(_ message: String) -> NSError {
        NSError(domain: "SILGallery", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
    static func galleryStop(_ process: Process) {
        if !process.isRunning { return }
        process.terminate()
        for _ in 0..<20 {
            if !process.isRunning { return }
            Thread.sleep(forTimeInterval: 0.025)
        }
        if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        process.waitUntilExit()
    }
    static func galleryExecute(_ executable: String, arguments: [String], input: Data,
                               timeout: TimeInterval = 30, outputLimit: Int = 32 * 1024 * 1024) throws -> GalleryProcessOutput {
        guard input.count <= 32 * 1024 * 1024, timeout > 0, outputLimit > 0 else {
            throw galleryFailure("Input or process limits are invalid.")
        }
        let manager = FileManager.default
        let folder = manager.temporaryDirectory.appendingPathComponent("SILGallery-" + UUID().uuidString, isDirectory: true)
        try manager.createDirectory(at: folder, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? manager.removeItem(at: folder) }
        let inputURL = folder.appendingPathComponent("input")
        let outputURL = folder.appendingPathComponent("stdout")
        let errorURL = folder.appendingPathComponent("stderr")
        try input.write(to: inputURL)
        try manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: inputURL.path)
        guard manager.createFile(atPath: outputURL.path, contents: nil, attributes: [.posixPermissions: 0o600]),
              manager.createFile(atPath: errorURL.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
            throw galleryFailure("Could not create compiler output files.")
        }
        let inputHandle = try FileHandle(forReadingFrom: inputURL)
        defer { inputHandle.closeFile() }
        let outputHandle = try FileHandle(forWritingTo: outputURL)
        defer { outputHandle.closeFile() }
        let errorHandle = try FileHandle(forWritingTo: errorURL)
        defer { errorHandle.closeFile() }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardInput = inputHandle
        process.standardOutput = outputHandle
        process.standardError = errorHandle
        try process.run()
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        do {
            while process.isRunning {
                let outputSize = try outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                let errorSize = try errorURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                if outputSize > outputLimit || errorSize > outputLimit {
                    throw galleryFailure("Compiler output exceeded the configured limit.")
                }
                if ProcessInfo.processInfo.systemUptime > deadline {
                    throw galleryFailure("Compiler process timed out.")
                }
                Thread.sleep(forTimeInterval: 0.02)
            }
            process.waitUntilExit()
            let outputSize = try outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            let errorSize = try errorURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard outputSize <= outputLimit, errorSize <= outputLimit else {
                throw galleryFailure("Compiler output exceeded the configured limit.")
            }
            return GalleryProcessOutput(stdout: String(decoding: try Data(contentsOf: outputURL), as: UTF8.self),
                                        stderr: String(decoding: try Data(contentsOf: errorURL), as: UTF8.self),
                                        status: process.terminationStatus)
        } catch {
            galleryStop(process)
            throw error
        }
    }
}

extension GalleryCommandPlan {
    func galleryArguments(_ program: String) -> [String]? {
        let modes = ["swiftc - -emit-silgen": "-emit-silgen", "swiftc - -emit-sil": "-emit-sil",
                     "swiftc - -dump-ast": "-dump-ast", "swiftc - -dump-parse": "-dump-parse",
                     "swiftc - -emit-ir": "-emit-ir", "swiftc - -emit-assembly": "-emit-assembly"]
        guard let mode = modes[program] else { return nil }
        var arguments = ["swiftc", "-", mode]
        if galleryLibrary { arguments += ["-parse-as-library", "-module-name", "SILInspector"] }
        if galleryWholeModule { arguments += ["-whole-module-optimization"] }
        if galleryOptimization { arguments += ["-O"] }
        return arguments
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
        guard let arguments = galleryPlan.galleryArguments(galleryProgram) else { return "Unsupported compiler mode." }
        galleryCommandText.stringValue = galleryPlan.galleryCompose(galleryProgram)
        let input = Data(gallerySource.utf8)
        guard input.count <= 2 * 1024 * 1024 else { return "Source exceeds the 2 MiB limit." }
        do {
            let output = try GalleryProcessExchange.galleryExecute("/usr/bin/xcrun", arguments: arguments, input: input)
            if output.stderr != "" && output.stderr != "\n" { return output.stderr }
            if output.status != 0 { return "Compiler exited with status \(output.status)." }
            if galleryDemangling {
                let demangled = try GalleryProcessExchange.galleryExecute("/usr/bin/xcrun", arguments: ["swift-demangle"], input: Data(output.stdout.utf8))
                if demangled.stderr != "" && demangled.stderr != "\n" { return demangled.stderr }
                if demangled.status != 0 { return "Demangler exited with status \(demangled.status)." }
                return demangled.stdout
            }
            return output.stdout
        } catch { return error.localizedDescription }
    }
}
