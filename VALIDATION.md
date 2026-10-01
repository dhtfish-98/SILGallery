# Validation

The isolated original and renamed application both build with current Xcode. Both use Swift language mode 5 and macOS deployment target 12; the unadapted historic deployment target is outside the SDK's supported range.

The behavior audit instantiates actual Cocoa controllers in hidden processes and checks:

- 96 compiler command compositions (16 option combinations across six views).
- 39 actual Swift compiler/demangler or subprocess error outputs, including stdout versus stderr selection.
- 10 XIB outlet connections and five application action connections against the compiled source declarations.

All comparisons pass. Swift AST/parse dump `decl_context=0x...` values are per-process compiler-memory identities and are the only output normalization; program addresses, instructions and compiler flags remain exact. The historical emitted library-mode module label is retained as compatibility data.

The audit removes only each application's entry annotation in temporary files so the test harness owns the process entry. It does not alter production files. The packaged application has been built, but manual interactive usage and every possible source program are not claimed as tested. The inherited subprocess pipe/error behavior remains unchanged.
