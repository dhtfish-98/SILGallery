"""Exercise the product process exchange with owned child programs and source."""
from pathlib import Path
import os
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]

def main():
    with tempfile.TemporaryDirectory(prefix='gallery-process-check-') as folder:
        work=Path(folder)
        exchange=work/'Exchange.swift'
        exchange.write_text((ROOT/'GallerySources/GalleryCompilation.swift').read_text().split('extension GalleryController {')[0])
        child=work/'Child.swift'
        child.write_text('''import Foundation
let mode=CommandLine.arguments[1]
if mode=="sleep" { Thread.sleep(forTimeInterval: 10) }
else if mode=="bytes" { FileHandle.standardOutput.write(Data([0xff,0xfe])) }
else if mode=="invalid-large" { FileHandle.standardOutput.write(Data(repeating: 0xff,count: 11*1024*1024)) }
else if mode=="invalid-stderr" { FileHandle.standardError.write(Data(repeating: 0xff,count: 11*1024*1024)) }
else {
    let block=Data(repeating: 65,count: 512*1024)
    FileHandle.standardError.write(block)
    FileHandle.standardOutput.write(block)
    let input=FileHandle.standardInput.readDataToEndOfFile()
    FileHandle.standardOutput.write(Data("\\ninput=\\(input.count)".utf8))
}
''')
        child_binary=work/'child'
        compiled=subprocess.run(['swiftc','-module-cache-path',str(work/'modules'),str(child),'-o',str(child_binary)],capture_output=True,text=True)
        assert compiled.returncode==0,compiled.stderr
        driver=work/'Driver.swift'
        driver.write_text('''import Foundation
@main struct GalleryProcessCheck {
    static func main() throws {
        let child=CommandLine.arguments[1]
        let modes=["swiftc - -emit-silgen","swiftc - -emit-sil","swiftc - -dump-ast","swiftc - -dump-parse","swiftc - -emit-ir","swiftc - -emit-assembly"]
        for mask in 0..<16 {
            let plan=GalleryCommandPlan(galleryLibrary: mask&1 != 0,galleryWholeModule: mask&2 != 0,galleryOptimization: mask&4 != 0,galleryDemangling: mask&8 != 0)
            for mode in modes {
                let args=plan.galleryArguments(mode)!
                precondition(args[0]=="swiftc" && args[1]=="-")
                precondition(args.contains("-parse-as-library") == (mask&1 != 0))
                precondition(args.contains("-whole-module-optimization") == (mask&2 != 0))
                precondition(args.contains("-O") == (mask&4 != 0))
                precondition(!args.contains("|") && !args.contains("swift-demangle"))
            }
            precondition(plan.galleryArguments("printf 'arbitrary-shell-command'")==nil)
        }
        let large=try GalleryProcessExchange.galleryExecute(child,arguments: ["exchange"],input: Data(repeating: 66,count: 1024*1024))
        precondition(large.status==0 && large.stderr.utf8.count==512*1024 && large.stdout.hasSuffix("input=1048576"))
        let invalidBytes=try GalleryProcessExchange.galleryExecute(child,arguments: ["bytes"],input: Data())
        precondition(invalidBytes.status==0 && !invalidBytes.stdout.isEmpty)
        let sampleURL=URL(fileURLWithPath: child).deletingLastPathComponent().appendingPathComponent("bounded-output")
        try Data(repeating: 65,count: 8).write(to: sampleURL)
        let exact=try GalleryProcessExchange.galleryReadOutput(sampleURL,limit: 8)
        precondition(exact=="AAAAAAAA")
        try Data(repeating: 65,count: 9).write(to: sampleURL)
        var excessRejected=false
        do { _=try GalleryProcessExchange.galleryReadOutput(sampleURL,limit: 8) } catch { excessRejected=true }
        precondition(excessRejected)
        try Data([0xff,0xfe]).write(to: sampleURL)
        let invalidUTF8=try GalleryProcessExchange.galleryReadOutput(sampleURL,limit: 6)
        precondition(invalidUTF8.utf8.count==6)
        var decodedLimitRejected=false
        do { _=try GalleryProcessExchange.galleryReadOutput(sampleURL,limit: 5) } catch { decodedLimitRejected=true }
        precondition(decodedLimitRejected)
        let bounded=try GalleryProcessExchange.galleryBoundedInput(invalidUTF8,limit: 6)
        precondition(bounded.count==6)
        var secondInputRejected=false
        do { _=try GalleryProcessExchange.galleryBoundedInput(invalidUTF8,limit: 5) } catch { secondInputRejected=true }
        precondition(secondInputRejected)
        for first in 0...255 {
            for second in 0...255 {
                let pair=[UInt8(first),UInt8(second)]
                let counted=try GalleryProcessExchange.galleryDecodedByteCount(Data(pair),limit: 32*1024*1024)
                precondition(counted==String(decoding: pair,as: UTF8.self).utf8.count)
            }
        }
        for sequence in [[0xe2,0x82],[0xe2,0x82,0x41],[0xf0,0x9f,0x8d,0x8e],[0xed,0xa0,0x80],[0x41,0xff,0xc3,0xa9]] {
            let bytes=sequence.map(UInt8.init)
            let counted=try GalleryProcessExchange.galleryDecodedByteCount(Data(bytes),limit: 32*1024*1024)
            precondition(counted==String(decoding: bytes,as: UTF8.self).utf8.count)
        }
        for mode in ["invalid-large","invalid-stderr"] {
            var rejected=false
            do { _=try GalleryProcessExchange.galleryExecute(child,arguments: [mode],input: Data()) } catch { rejected=true }
            precondition(rejected,mode)
        }
        for invalidLimit in [0,-1,Int.max,32*1024*1024+1] {
            var rejected=false
            do { _=try GalleryProcessExchange.galleryReadOutput(sampleURL,limit: invalidLimit) } catch { rejected=true }
            precondition(rejected)
        }
        for invalidTimeout in [Double.nan,Double.infinity,-Double.infinity,0,-1] {
            var rejected=false
            do { _=try GalleryProcessExchange.galleryExecute(child,arguments: ["bytes"],input: Data(),timeout: invalidTimeout) } catch { rejected=true }
            precondition(rejected)
        }
        for invalidLimit in [0,-1,Int.max,32*1024*1024+1] {
            var rejected=false
            do { _=try GalleryProcessExchange.galleryExecute(child,arguments: ["bytes"],input: Data(),outputLimit: invalidLimit) } catch { rejected=true }
            precondition(rejected)
        }
        for scenario in ["timeout","output","input","launch"] {
            var failed=false
            do {
                switch scenario {
                case "timeout": _=try GalleryProcessExchange.galleryExecute(child,arguments: ["sleep"],input: Data(),timeout: 0.1)
                case "output": _=try GalleryProcessExchange.galleryExecute(child,arguments: ["exchange"],input: Data(),outputLimit: 1024)
                case "input": _=try GalleryProcessExchange.galleryExecute(child,arguments: [],input: Data(repeating: 0,count: 33*1024*1024))
                default: _=try GalleryProcessExchange.galleryExecute("/no/such/compiler",arguments: [],input: Data())
                }
            } catch { failed=true }
            precondition(failed,scenario)
        }
        let source=String(repeating: "// owned comment\\n",count: 32000)+"public func ownedAdd(_ a: Int, _ b: Int)->Int { a+b }"
        let output=try GalleryProcessExchange.galleryExecute("/usr/bin/xcrun",arguments: ["swiftc","-","-emit-sil"],input: Data(source.utf8))
        precondition(output.status==0 && output.stdout.contains("ownedAdd"))
        let malformed=try GalleryProcessExchange.galleryExecute("/usr/bin/xcrun",arguments: ["swiftc","-","-emit-sil"],input: Data("public func {".utf8))
        precondition(malformed.status != 0 && !malformed.stderr.isEmpty)
        print("PASS: 96 fixed compiler plans, raw and replacement-UTF8 output budgets, bounded demangler input, finite timeout/output limits, process failures, large and invalid Swift source.")
    }
}
''')
        binary=work/'check'
        compiled=subprocess.run(['swiftc','-module-cache-path',str(work/'modules'),'-swift-version','5','-parse-as-library',str(exchange),str(driver),'-o',str(binary)],capture_output=True,text=True)
        assert compiled.returncode==0,compiled.stderr
        environment=dict(os.environ,CLANG_MODULE_CACHE_PATH=str(work/'modules'),SWIFT_MODULE_CACHE_PATH=str(work/'modules'))
        result=subprocess.run([str(binary),str(child_binary)],capture_output=True,text=True,timeout=60,env=environment)
        assert result.returncode==0,result.stderr
        print(result.stdout.strip())

if __name__=='__main__':main()
