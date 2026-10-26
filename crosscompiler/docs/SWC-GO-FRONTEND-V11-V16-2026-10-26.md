# SWC Go-Frontend Units V11–V16 — 2026-10-26

## Integrated native Semantic units

The active SWC graph now contains the closed V11 ASCII lexer, V12 bounded parser, V13 Rich-to-Core bridge helpers, and the V14–V16 compiler/primitive module units. The source units and upstream READMEs are retained under `src/units/frontend/go/`; non-executable contract overlays are retained separately under `src/units/frontend/go/contracts/`.

- Source units scanned: 225
- Distinct function bindings selected: 305
- Closures merged: 298 (7 duplicate bindings deduplicated)
- Missing selected bindings: 0
- Unresolved callees in the imported closures: 0
- Resulting graph: 49,857 nodes / 60,644 relations

The import was graph-based: closure subgraphs and their Semantic relations were copied/remapped by the existing importer. The V14/V15/V16 contract overlays remain separate evidence; they were not represented as executable functions.

## Build and self-host evidence

| Artifact | Bytes | SHA256 |
|---|---:|---|
| Active `swc.exe` (Stage 1) | 402,944 | `81ADEFC7BCD26C5F914E985875CD979616B81332FCE703343563433362732959` |
| Stage 2 | 402,944 | `81ADEFC7BCD26C5F914E985875CD979616B81332FCE703343563433362732959` |
| Stage 3 | 402,944 | `81ADEFC7BCD26C5F914E985875CD979616B81332FCE703343563433362732959` |
| Active SE graph | 12,883,932 | `F1C8B37700CDCC1D38857A9D9BD92EDE3CBE880800310A6320A263DA452BD8E4` |

The active SMOD `--embed-all` build completed successfully and reproduced the same 402,944-byte EXE and SHA. The prior active EXE was 343,552 bytes (`ED889C815874AF4E057A959E6D9793E6A44D0520FB70E829FC202240757EDF5B`) and is preserved with its matching SE/SMOD in `backup/before-go-v16-integration-20261026/`.

## Native execution checks through SWC

| Input SE | Output PE | Native process exit |
|---|---:|---:|
| V11 `GoFrontend-Core-Closed-Smoke.se` | 29,184 bytes | 42 |
| V12 `GoFrontend-V12-Smoke.se` | 30,208 bytes | 42 |
| V16 `Go-V16-SelfTest.se` | 25,600 bytes | 0 (all 51 encoded checks passed) |

These prove that the imported Semantic lexer/parser/helper closures are callable, lowered by SWC, emitted as native PE code, and execute. They do not prove arbitrary `.go` source ingestion.

## Remaining Go CLI integration blocker

The existing `swc transpile go semantic <input.go> -o <output.se>` command still crashes on both the previous baseline and the new candidate with Windows access-violation status `-1073741819` (`0xC0000005`). The input file used was the package's `examples/arithmetic.go`; no output was produced.

The source graph contains this cycle:

`transpile_with_semantics` → `transpile_matrix_dispatch_languages` → `transpile_matrix_dispatch_13x13` → `transpile_with_semantics`

That cycle is the immediate crash cause. Separately, V12's parser accepts only two packed 64-bit words (at most 16 ASCII bytes) and returns a packed expression value; it does not construct a UAST. V16's supplied `compile_go_subset.py` parses Go in Python and is not embedded in SWC. The original Rich Go frontend has unresolved Go-runtime calls and was not falsely marked as native.

Therefore this candidate has the Go Core SE functions compiled and callable, but **the `swc transpile ... .go` frontend-to-UAST-to-backend path is not yet connected**. The next change must replace the recursive matrix dispatch with a real, supported Go source frontend and preserve fail-closed behavior for unsupported Go syntax.
