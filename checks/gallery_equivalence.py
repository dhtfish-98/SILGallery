from pathlib import Path
import argparse
import json
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

def gallery_driver(gallery_new):
    gallery_type = 'GalleryController' if gallery_new else 'AppDelegate'
    gallery_fields = ['galleryLibrary', 'galleryWholeModule', 'galleryOptimization', 'galleryDemangling'] if gallery_new else ['parseAsLibrary', 'moduleOptimize', 'optimize', 'demangle']
    gallery_source_field = 'gallerySourcePane' if gallery_new else 'sourceView'
    gallery_command_field = 'galleryCommandText' if gallery_new else 'programText'
    gallery_run_method = 'galleryRunCommand' if gallery_new else 'runProgram'
    gallery_compose = ('GalleryCommandPlan(galleryLibrary: auditController.galleryLibrary, galleryWholeModule: auditController.galleryWholeModule, '
                       'galleryOptimization: auditController.galleryOptimization, galleryDemangling: auditController.galleryDemangling).galleryCompose(auditCommand)' if gallery_new else
                       'auditController.withDemangle(auditController.withOptimize(auditController.withModuleOptimize(auditController.withParseAsLibrary(auditCommand))))')
    gallery_settings = '\n'.join('auditController.' + gallery_name + ' = (auditMask & ' + str(1 << gallery_index) + ') != 0'
                                 for gallery_index, gallery_name in enumerate(gallery_fields))
    gallery_reset = '\n'.join('auditController.' + gallery_name + ' = false' for gallery_name in gallery_fields)
    return '''import Cocoa
import Foundation
import ObjectiveC
@main struct GalleryBehaviorAudit {
    static func main() {
        let auditApp = NSApplication.shared
        auditApp.setActivationPolicy(.prohibited)
        let auditSourcePane = NSScrollView()
        let auditSourceText = NSTextView()
        auditSourceText.string = "public func ownedAdd(_ ownedLeft: Int, _ ownedRight: Int) -> Int { ownedLeft + ownedRight }"
        auditSourcePane.documentView = auditSourceText
        let auditCommandText = NSTextField()
        let auditController = ''' + gallery_type + '''()
        auditController.''' + gallery_source_field + ''' = auditSourcePane
        auditController.''' + gallery_command_field + ''' = auditCommandText
        let auditModes = ["swiftc - -emit-silgen", "swiftc - -emit-sil", "swiftc - -dump-ast", "swiftc - -dump-parse", "swiftc - -emit-ir", "swiftc - -emit-assembly"]
        var auditCommands: [String] = []
        var auditOutputs: [String] = []
        for auditMask in 0..<16 {
            ''' + gallery_settings + '''
            for auditCommand in auditModes {
                let auditComposed = ''' + gallery_compose + '''
                auditCommands.append(auditComposed)
                if [0, 1, 2, 4, 8, 15].contains(auditMask) {
                    auditOutputs.append(auditController.''' + gallery_run_method + '''(auditCommand))
                    precondition(auditCommandText.stringValue == auditComposed)
                }
            }
        }
        ''' + gallery_reset + '''
        for auditCommand in ["printf 'owned-ok'", "printf '\\n' >&2; printf 'owned-output'", "printf 'owned-error' >&2; printf 'owned-output'"] {
            auditOutputs.append(auditController.''' + gallery_run_method + '''(auditCommand))
        }
        let auditReport: [String: Any] = ["commands": auditCommands, "outputs": auditOutputs]
        let auditBytes = try! JSONSerialization.data(withJSONObject: auditReport, options: [.sortedKeys])
        print(String(data: auditBytes, encoding: .utf8)!)
    }
}
'''

def gallery_main():
    gallery_parser = argparse.ArgumentParser()
    gallery_parser.add_argument('--reference', type=Path, required=True)
    gallery_parser.add_argument('--output', type=Path)
    gallery_args = gallery_parser.parse_args()
    gallery_root = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='gallery-output-audit-') as gallery_temp:
        gallery_work = Path(gallery_temp)
        gallery_original = gallery_work / 'OriginalController.swift'
        gallery_original.write_text(gallery_args.reference.read_text().replace('@NSApplicationMain', ''))
        gallery_reports = []
        for gallery_new in [False, True]:
            gallery_label = 'new' if gallery_new else 'original'
            gallery_sources = [gallery_original]
            if gallery_new:
                gallery_sources = []
                for gallery_file in sorted((gallery_root / 'GallerySources').glob('*.swift')):
                    gallery_copy = gallery_work / gallery_file.name
                    gallery_copy.write_text(gallery_file.read_text().replace('@NSApplicationMain', ''))
                    gallery_sources.append(gallery_copy)
            gallery_harness = gallery_work / (gallery_label + '_Harness.swift')
            gallery_harness.write_text(gallery_driver(gallery_new))
            gallery_executable = gallery_work / (gallery_label + '_Harness')
            gallery_compile = subprocess.run(['swiftc', '-swift-version', '5', '-parse-as-library', '-module-name',
                                               'SILGallery' if gallery_new else 'SILInspector'] +
                                              [str(gallery_file) for gallery_file in gallery_sources] +
                                              [str(gallery_harness), '-o', str(gallery_executable)], capture_output=True, text=True)
            assert gallery_compile.returncode == 0, gallery_compile.stderr
            gallery_run = subprocess.run([str(gallery_executable)], capture_output=True, text=True, timeout=180)
            assert gallery_run.returncode == 0, gallery_run.stderr
            gallery_reports.append(json.loads(gallery_run.stdout))
        gallery_original_report, gallery_new_report = gallery_reports
        if gallery_args.output:
            gallery_args.output.with_name('SILGallery-output-detail.json').write_text(json.dumps(gallery_reports, indent=2) + '\n')
        assert gallery_original_report['commands'] == gallery_new_report['commands']
        # Swift AST/parse dumps expose per-process declaration-context pointers.
        # Only those explicitly labelled compiler-memory values are normalized.
        gallery_normalize = lambda gallery_text: re.sub(r'decl_context=0x[0-9a-fA-F]+', 'decl_context=<compiler-memory>', gallery_text)
        assert [gallery_normalize(gallery_text) for gallery_text in gallery_original_report['outputs']] == [gallery_normalize(gallery_text) for gallery_text in gallery_new_report['outputs']], [
            gallery_index for gallery_index, (gallery_left, gallery_right) in enumerate(zip(gallery_original_report['outputs'], gallery_new_report['outputs']))
            if gallery_normalize(gallery_left) != gallery_normalize(gallery_right)]
        assert gallery_new_report['outputs'][-3:] == ['owned-ok', 'owned-output', 'owned-error']

    gallery_xml = ET.parse(gallery_root / 'GallerySources/Base.lproj/GalleryMenu.xib')
    gallery_owner = gallery_xml.getroot().find('.//*[@customClass="GalleryController"]')
    assert gallery_owner is not None
    gallery_controller_id = gallery_owner.attrib['id']
    gallery_code = '\n'.join(gallery_file.read_text() for gallery_file in (gallery_root / 'GallerySources').glob('*.swift'))
    gallery_outlets = [gallery_item.attrib['property'] for gallery_item in gallery_owner.findall('.//outlet')]
    for gallery_outlet in gallery_outlets:
        assert re.search(r'\bvar\s+' + re.escape(gallery_outlet) + r'\s*:', gallery_code), gallery_outlet
    gallery_actions = [gallery_item.attrib['selector'].rstrip(':') for gallery_item in gallery_xml.findall('.//action')
                        if gallery_item.attrib.get('target') == gallery_controller_id]
    for gallery_action in gallery_actions:
        assert re.search(r'@IBAction\s+func\s+' + re.escape(gallery_action) + r'\(', gallery_code), gallery_action
    gallery_result = {'status': 'PASS', 'project': 'SILGallery', 'command_compositions': len(gallery_new_report['commands']),
                      'compiler_and_error_outputs': len(gallery_new_report['outputs']),
                      'outlet_connections_checked': len(gallery_outlets), 'action_connections_checked': len(gallery_actions),
                      'normalization': 'Only decl_context compiler-memory addresses in AST/parse dumps; emitted program addresses and instructions remain exact.',
                      'scope': 'Real Cocoa controllers in hidden audit processes, real Swift compiler/demangler output, XIB connections. Manual interactive application use is not claimed.'}
    if gallery_args.output:
        gallery_args.output.write_text(json.dumps(gallery_result, indent=2) + '\n')
    print(json.dumps(gallery_result))

if __name__ == '__main__':
    gallery_main()
