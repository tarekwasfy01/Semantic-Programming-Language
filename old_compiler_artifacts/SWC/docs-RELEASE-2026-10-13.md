# SWC Windows update — 2026-10-15

Historical report. The current active Windows release is documented in
[RELEASE-2026-10-16.md](RELEASE-2026-10-16.md), including the import-free runtime,
SMOD/path repairs and 38 passing native checks. Status statements below describe
the older artifacts and must not be interpreted as current failures.

## 2026-10-15 compiler candidate and arity status

The current workspace source candidate is 5,721,230 bytes, SHA256
`64CEDDE1265ABD44F427E0B459A61AFE7834069AFAF17791E8951F14B089CFBC`.
Its matching `swc.exe` is 161,280 bytes, SHA256
`CC213E4BFCB5F8E6FFAB2F6C2279BB7D91F4902FF41FAC16B6008B2EF2476BD5`.
Stage 2 and Stage 3 were reported byte-identical for this candidate.

The `mem_store64` fail-closed arity behavior is **not proven**: the zero-,
one-, two-, and three-argument negative fixtures were accepted with exit code
0. The new `matrix-intrinsic-arity-rejected.se` records this regression probe;
it is evidence of an unresolved validation gap, not a passing rejection test.
On 2026-10-15 this candidate was promoted to `crosscompiler/bin/swc.exe` after
the reported Stage2/Stage3 byte-identical selfhost. The previous 146,432-byte
Windows binaries and the smaller experimental candidates were moved into the
existing `old_compiler_artifacts/SWC/` archive. The arity regression above
remains open and is not represented as passing.

This existing release-document path is updated in place.

## Previously activated baseline (2026-10-13)

The following validation record describes the 146432-byte baseline before the
2026-10-15 promotion; it is retained as historical evidence.

Historical `bin/swc.exe`: 146432 bytes, SHA256
`39DAE62B08BDB1362C05BEF46C9315D121255E074C78ABDE883E8CF410AB4DD9`.
The current 161280-byte binary and its SHA are recorded above.

The matching Windows source is 5194544 bytes, SHA256
`1F8C8A04E000D653BCB0A60DA6DBA9673689529CFF7234C4FBB6EC573D8FE74B`.
`manifests/swc.smod` references that source using repository-relative paths and
the matching size/hash. Selfhost Stage2, Stage3 and native `--embed-all` SMOD
builds match the activated executable byte for byte.

Validated examples include flat named-local tuple destructuring (42), ordered
effectful destructuring (13), integer negate (-42), integer complement (-43),
boolean-not for zero/nonzero/nested input, numeric relation node IDs (8), and
ReturnStmt `value` operands (42). Arity mismatches and unsupported unary
operations/missing unary operands are rejected. The last complete release
fixture run tested 45 documents: 38 compiled and 32 declared runtime results
matched. Counts do not imply whole-family semantic coverage; several legacy
fixtures are only literal-return smoke tests.

## Development sources, not activated features

The shared units and patch scripts include the subsequent loop/foreach,
member/index and slice work. They are preserved so development can continue.
The separate loop-context candidates remain historical artifacts in the
existing old-compiler archive; they are not the current active binary.

The experimental foreach integration still failed its candidate build. The
member/index experiment still had failing native rejection tests. The bounded
slice ABI is unproven, and the later identity-view patch has no successful
native validation. These paths must not be described as released support.
New regression fixtures describing those requirements are included as pending
tests and can fail with the active compiler.

Nested/rest/wildcard binding patterns, general field-layout-driven member
access, bounded slicing, and full transpiler parity remain incomplete.
The Windows update does not revalidate the retained Linux/macOS binaries.

## Reproduction tools

Relevant existing workspace tools are supplied under the repository's existing
`scripts/` directory with their existing tool names. Their filesystem-oriented patch
commands create candidates and do not themselves prove native execution.
Build the released compiler directly from `crosscompiler/manifests/swc.smod`.
Use forward slashes in that input argument; the current manifest resolver
does not recognize backslash separators when finding the manifest directory.
