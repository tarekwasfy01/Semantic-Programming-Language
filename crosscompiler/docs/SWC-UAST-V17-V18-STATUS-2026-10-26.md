# SWC UAST V17/V18 integration status — 2026-10-26

## Promoted selfhost candidate

`swc.exe` and `src/swc-selfhost-windows.se` now point to the validated V17-contract candidate. The prior active files and manifest are preserved under `backup/before-uast-v17-contract-promotion-20261026/`.

- Prior EXE: 402,944 bytes, SHA-256 `81ADEFC7BCD26C5F914E985875CD979616B81332FCE703343563433362732959`.
- Promoted EXE: 407,552 bytes, SHA-256 `B37F784751F2909B357DD068F70598F3A26E839863B9AEDA30EDF1D0D921902A`.
- Stage 1, Stage 2 and Stage 3 SHA-256 values match; Stage 2 and Stage 3 exited 0.
- The SMOD manifest was updated to the promoted source hash and marks Stage2/Stage3 selfhost verification.
- The 19 imported V17 closures are executable contract predicates/checkers. They are not 19 native implementations of the corresponding UAST kinds.

## V18 findings

V18 records 94 local contracts: 83 typed lazy Boolean `&&`/`||` rewrites, 8 Boolean equality rewrites, one Boolean `!`, and two Boolean literal specializations. It lowers logical expressions to Core `ConditionalExpr`, preserving left-to-right evaluation and evaluating the right operand conditionally.

The supplied six Core-SE Boolean fixtures were compiled by the promoted candidate and executed on Windows: **6/6 expected exit codes** (0, 0, 1, 0, 1, 1). These fixtures already contain Core conditional expressions. This verifies the existing SWC Core conditional/native emission path; it does not prove that SWC itself transforms a raw rich Go `OperationExpr` into that Core form.

The V18 package's native Boolean smoke tests use its Python reference x64 backend and Linux ELF outputs, not SWC. The package explicitly leaves 10,186 blocking obligations and sets `fully_native_ready=false`. The full V18 merged compiler graph was tried with SWC and rejected with exit code 3; the package's compile gate also refuses it. The V18 `UAST18-Contract-Overlay.se` is explicitly non-executable and was not merged as compiler code.

An existing raw `logical_and` short-circuit fixture still fails compilation with exit code 3. Thus raw rich-operation lowering remains open despite the six successful already-lowered Core fixtures.

## Boundary of the claim

This promotion is a selfhost-stable graph expansion and preserves the current active compiler. **It does not make the complete 19-kind UAST or the Go frontend fully natively executable.** Remaining work is to implement and wire the rich-to-core rewrite into SWC's actual reader/lowering path, then address the V18 obligations (runtime/value model, unresolved and indirect calls, loops/control-flow, non-integer literals and type specialization) with native SWC evidence.
