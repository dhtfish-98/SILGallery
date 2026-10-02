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
        print("PASS: 96 fixed compiler plans, rejected shell mode, 1 MiB input with both output streams, invalid bytes, timeout/size/launch errors, large and invalid Swift source.")
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
