# V19 native Windows SWC integration

The active compiler integrates the executable V19 loop contracts and control
semantics directly in Semantic. It retains native parallel function compilation
and reproduces itself byte-for-byte through the repository manifest.

## Implemented in the compiler

- All six callable contract closures are linked into the complete compiler.
  Their original units are in `source/shared/se/units/uast19-`.
- The reader retains `semantic.control_target` as an internal control relation,
  separate from syntax children. It checks the source/target kinds, transfer role,
  ordinal, missing flag and duplicate edges. Explicit `target_loop_id` fields
  must agree with the edge and nearest enclosing loop.
- Each function resets its lexical loop state. While and foreach emission save
  and restore that state across nested loops. Context byte 296 belongs to each
  worker's private context; it stores the loop ID plus one, or zero outside loops.
  Control transfers across closure boundaries are rejected.
- Ordinary loops require exactly one condition and one body. `continue` targets
  the while test or the foreach advancement path; `break` targets the loop exit.
- Scope compilation respects ordered statement edges with gaps in their ordinal
  values, including a gap before the first statement. This executes the original
  archive fixtures without renumbering or rewriting them outside the compiler.
- Parser errors survive into the compile gate and prevent output publication.

The complete implementation and hooks are in
`source/windows/se/swc-selfhost-windows.se`. The four new helper closures are also
available in `source/shared/se/units/swc-uast19-native.se`. The native compiler
requires neither Python nor the archive's reference backend.

## Native verification

The recorded verification performs 24 checks against Windows PE programs:

| Cases | Result |
| --- | --- |
| Original continue/break, nested loops, while-true/break | exits 4, 5, 6 |
| Original specialized fixed-literal foreach | exit 10 |
| Original six-contract executable | exit 6 |
| Direct ForEachStmt with integer AggregateExpr, continue and break | exit 7 |
| Combined 13-function regression with 1, 2 and automatic workers | exit 38; identical output bytes |
| Six original V18 Core conditional / lazy Boolean cases | all expected exits; skipped trap branches remain unexecuted |
| Nine malformed or unsupported control/iteration cases | compile exit 3; existing output preserved |

Negative cases cover mismatched field and edge targets, a missing explicit edge,
duplicate control edges, an invalid transfer role, duplicate loop conditions,
dynamic foreach sequences, break outside a loop and cross-closure control flow.

The seven additional checks also pass. Selfhost builds use
12 workers for 1,712 functions on the validation machine; Stage 3 was observed
with 13 native threads including its main thread. The active compiler, Stage 2
and Stage 3 have identical hashes, and Stage 3 freshly compiles and runs return42.
Current hashes and results are recorded in `selfhost_validation.json`,
`uast19_validation.json` and `parallel_validation.json`.

Reproduce from the repository root:

```powershell
$env:SWC_THREADS = '0'
$env:SWC_PARALLEL_TRACE = '1'
```

## Archive provenance and remaining scope

Input: `Semantic-Document-1-UAST-Lowering-V19-2026-10-26.zip`, SHA-256
`DC001E5D230AB6B5C26372B23D02876052B01977406BA69BAA5532C44D042454`.
The archive's bundled older SWC binary and Python reference backends were not
promoted. Its declarative contract overlays remain documentation, rather than
being counted as executable compiler implementations.

The already-specialized Core foreach fixture is compiled directly. The raw
literal-aggregate fixture exercises SWC's native aggregate/foreach backend; it
does not invoke or embed the Python static-specialization pass. SWC uses lexical
state during emission instead of adding new edges to source files.

**The full archived Go frontend is still not native-ready.** The final active
SWC rejects `core/Semantic Document 1.se` with exit 3. The archive reports 10,186
unresolved native obligations, dynamic iterator requirements, 23 controls without
an enclosing structural loop, and an unproven global tagged-value model. That
historical obligation total has not been recomputed or claimed resolved here.
The [typed Boolean subset](SWC-TYPED-BOOLEAN-NATIVE-2026-10-26.md) now lowers
natively. The complete Go frontend and Go transpile CLI remain incomplete. Linux and
macOS compiler roots retain their previous status.

Later native integration: [V20 integer switches and V21 packed-byte subset](SWC-UAST-V20-V21-NATIVE-2026-10-26.md). General Go runtime limits above remain.
