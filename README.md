# SILGallery

SILGallery is a macOS companion application for inspecting Swift source, raw/canonical SIL, AST, parser output, LLVM IR and assembly.

## Build

Use macOS 12 or newer with Xcode and the Swift compiler:

```sh
xcodebuild -project SILGallery.xcodeproj -target SILGallery -configuration Release CODE_SIGNING_ALLOWED=NO build
```

The app uses the system `swiftc` and `xcrun swift-demangle`. All six compiler views, font-size control, demangling, optimization, whole-module optimization and library parsing remain available. Build output in the release archive is unsigned; source is provided for rebuilding.

## Organization

- `GallerySources/GalleryController.swift`: view outlets and state.
- `GallerySources/GalleryActions.swift`: user actions and Cocoa protocol callbacks.
- `GallerySources/GalleryCompilation.swift`: command plans and subprocess exchange.
- `GallerySources/Base.lproj/GalleryMenu.xib`: synchronized menu, outlet and action connections.
- `checks/gallery_equivalence.py`: isolated original/new controller and compiler-output comparison.

The emitted compiler module label `SILInspector` is preserved as wire compatibility data so library-mode SIL/IR stays identical. Cocoa protocol callbacks, system APIs, implicit Swift setter names and required Xcode metadata filenames retain their framework roles. Other application implementation names and source/resource filenames are rewritten.

## Verify

Check out the exact upstream commit from [ORIGIN.md](ORIGIN.md), then run:

```sh
python3 checks/gallery_equivalence.py --reference /path/to/upstream/SILInspector/AppDelegate.swift
```

See [VALIDATION.md](VALIDATION.md) for the actual checks and their scope.
