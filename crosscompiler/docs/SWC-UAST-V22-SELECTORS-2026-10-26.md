# V22 selector integration in the Windows Semantic compiler

The six executable closures `u22_select_1` through `u22_select_5` and
`u22_select_selftest` from the supplied V22 package are linked directly into the
Semantic compiler source. The imported closures retain their own Semantic
control-flow and call-target relations. The existing compiler entry point stays
unchanged. The import report resolves all selected transitive callees.

`verify-uast22-selectors.ps1` builds and executes the package's original
self-test and a separate boundary program. The boundary program checks every
valid index and the negative and upper-bound index for each of the five
selectors: 25 assertions. Both programs are compiled using 1, 2 and automatic
worker selection; each executable is required to have identical bytes across
the three modes. The original self-test returns 25; the boundary program
returns 42 only if all 25 comparisons succeed.

This integration makes the selector functions available as compiler functions;
it does not yet lower raw V22 arrays, tuples, copying slices, float or string
comparisons. The explicit zero-pointer case is described in [pointer-null status](SWC-UAST-V22-POINTER-NULL-2026-10-26.md). The complete Go frontend and
full UAST lowering are not established. V22's original test reports use a
separate reference backend; the verification above runs actual Windows binaries
emitted by SWC.

Source archive SHA-256:
`C50F57F3CB958C91EBF608C3D8829FFE42E3B255BEA40A7325430C304741E099`.
Reproduce with `./crosscompiler/verify-uast22-selectors.ps1` and
`./crosscompiler/verify-selfhost.ps1`.
