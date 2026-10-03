> 目录已整理：文档在「项目文档」，构建、缓存与暂存输入在「Build」。从仓库根目录运行 `python3 构建.py --build`；如需使用本文原有源码命令，先运行 `python3 构建.py --stage --ci`，再进入 `Build/源码`。暂存会恢复原输入路径。现有版本和历史验证记录按各自提交理解。

# SILGallery

防御用途、实际能力及本轮验证范围见 [DEFENSIVE_SCOPE.md](<DEFENSIVE_SCOPE.md>)。

SILGallery is a macOS companion application for inspecting Swift source, raw/canonical SIL, AST, parser output, LLVM IR and assembly.

## Build

Use macOS 12 or newer with Xcode and the Swift compiler:

```sh
xcodebuild -project SILGallery.xcodeproj -target SILGallery -configuration Release CODE_SIGNING_ALLOWED=NO build
```

The app launches `/usr/bin/xcrun` with fixed `swiftc` or `swift-demangle` arguments. Arbitrary shell command strings are rejected. Process input/output use private temporary files to avoid pipe deadlocks. Source input is capped at 2 MiB, each output stream is checked against 32 MiB, and each child has a 30-second timeout. All six compiler views, font-size control, demangling, optimization, whole-module optimization and library parsing remain available. Build output in the release archive is unsigned; source is provided for rebuilding.

## Organization

- `GallerySources/GalleryController.swift`: view outlets and state.
- `GallerySources/GalleryActions.swift`: user actions and Cocoa protocol callbacks.
- `GallerySources/GalleryCompilation.swift`: command plans and subprocess exchange.
- `GallerySources/Base.lproj/GalleryMenu.xib`: synchronized menu, outlet and action connections.
- `checks/gallery_equivalence.py`: isolated original/new controller and compiler-output comparison.

The emitted compiler module label `SILInspector` is preserved as wire compatibility data so library-mode SIL/IR stays identical. Cocoa protocol callbacks, system APIs, implicit Swift setter names and required Xcode metadata filenames retain their framework roles. Other application implementation names and source/resource filenames are rewritten.

## Verify

Check out the exact upstream commit from [ORIGIN.md](<ORIGIN.md>), then run:

```sh
python3 checks/gallery_equivalence.py --reference /path/to/upstream/SILInspector/AppDelegate.swift
python3 checks/gallery_process_safety.py
```

See [VALIDATION.md](<VALIDATION.md>) for the actual checks and their scope.

Earlier v1.0.0 packages contain the inherited subprocess exchange. Rebuild the current source for the defensive process policy.
