# Native V20/V21 integration in parallel Windows SWC

The active SWC integrates both supplied archives directly in Semantic. It adds
seven callable V20 switch contracts, 20 callable V21 runtime functions, native
integer-switch emission and native packed-byte UAST lowering. The original
compiler main remains the CLI entry point. The archives' older binaries and
Python reference backends are not used as the active compiler.

## V20 integer switches

`OperationExpr` with `fields.kind=switch` accepts one discriminator, nonempty
ordered `switch_case` nodes, at most one default and unique constant signed-i64
patterns. Decimal case constants are checked for syntax and signed overflow.
The discriminator is evaluated once. Explicit patterns are checked before
default dispatch regardless of default's source position. Cases do not fall
through implicitly. Type/value-switch runtimes and nonliteral patterns are
rejected.

Break exits the nearest loop or switch. Continue targets the nearest loop,
including when nested inside a switch. Explicit `target_id`, `target_loop_id`,
`target_kind`, transfer roles and `semantic.control_target` edges must agree
with lexical state. Each function resets its state, so a closure cannot jump
into an enclosing function's loop or switch. All loop emitters, including the
V21 iterator, preserve the nearest breakable construct across nested bodies.

Context byte 312 stores the nearest breakable node ID plus one; byte 296 retains
the nearest loop. Both are private to each compiler worker. Case labels use
range 11 and switch exits range 12; the label table reserves 13 ranges to keep
existing conditional, loop, string, index and foreach labels disjoint.

## V21 explicit packed-byte specialization

Only the explicit marker `uast21.packed_u8_array_6`, supplied through
`type_ref.kind` or `uast21_operand_type`, selects this representation. It requires
zero-based indexing and the explicit Core value model. It stores up to six bytes
and their length in one nonnegative i64. It does not infer that generic Go
slices or arbitrary aggregates have this representation.

The native emitter handles marked AggregateExpr, read-only IndexExpr, SliceExpr
with explicit lower/upper arguments, and ForEachStmt. Arguments are evaluated
once, left to right. A foreach sequence is evaluated once; its iterator advances
before the body so continue always progresses. Runtime checks reject invalid
bytes, indices, lengths and slice bounds with the documented -1 result. A slice
is copied by value, without Go aliasing/capacity semantics. Index writes are
rejected.

When a program uses this specialization, SWC reads its embedded **Semantic**
runtime library, places its nodes and relations after the program's IDs, and
resolves private runtime function names before starting the worker pool. The
target executable contains native runtime code and needs no external SE file,
Python runtime, Go runtime or Python preprocessing pass. The 20 original public
runtime functions are also linked into the complete compiler source.

The runtime library is retained in
`source/shared/se/units/uast21-native-runtime-library.se`. Private names reserve
the `__swc_u21_` prefix; conflicting definitions are rejected. Original public
modules and contracts are retained under `units/uast20/` and `units/uast21/`.
Compiler helpers are mirrored in `swc-uast20-switch-native.se` and
`swc-uast21-packed-native.se` in that units directory.

## Native evidence

- All six original V20 switch programs and its seven-contract executable run
  with their expected exits. Additional cases cover i64 extrema, one-time
  discriminator effects, no-match dispatch and a switch inside a packed iterator.
- Fourteen malformed or unsupported switch cases are rejected, including
  duplicate cases/defaults, missing discriminators, type/dynamic switches,
  nonliteral/float/overflow cases and invalid control targets/transfers.
- All six original V21 Core programs and six directly authored equivalent **raw
  UAST** programs run. Raw programs do not include runtime definitions, proving
  automatic native runtime inclusion. Additional cases exercise empty/invalid
  vectors, dynamic bounds, side-effect ordering and break/continue progression.
- All **221 supplied runtime vectors** are compared as full i64 values in an
  actual Windows PE executable, including 48 cases expecting -1. The assertion
  program and raw UAST fixture reproduce identical bytes with 1, 2 and automatic
  workers. Switch call graphs also reproduce identical bytes across these modes.
- The complete suite has **226 build/execution/rejection checks**, including the
  previous 39 Boolean, 24 V19/Core and seven parallel checks, plus 15 direct-call
  argument-order checks and six V22 selector checks and 12 explicit pointer-null checks and six V23 Core checks and 16 raw source-UAST checks and 39 float/legacy-Boolean build/execution/rejection checks. The 221 individual
  runtime assertions are recorded separately from those build/run checks.
- The 1,751-function selfhost selects 12 workers. The active compiler and two
  fresh builds from `manifests/swc.smod` have identical hashes. Stage 3 freshly
  compiles and runs return42. A runtime assertion compilation was observed with
  13 native threads including the main thread.

Reproduce from the repository root:

```powershell
$env:SWC_THREADS = '0'
$env:SWC_PARALLEL_TRACE = '1'
./crosscompiler/verify-uast20.ps1
./crosscompiler/verify-uast21.ps1
./crosscompiler/verify-boolean.ps1
./crosscompiler/verify-uast19.ps1
./crosscompiler/verify-parallel.ps1
./crosscompiler/verify-call-order.ps1
./crosscompiler/verify-selfhost.ps1
```

Current hashes and native results are in `selfhost_validation.json`,
`uast20_validation.json`, `uast21_validation.json`, `boolean_validation.json`,
`uast19_validation.json`, `parallel_validation.json` and `call_order_validation.json`.

## Provenance and remaining scope

Input archive SHA-256:

- V20: `0A788AF16E15A92C2520835AE374832DB86A4541A4E0687D7AB62E5025EF1333`
- V21: `04BFF12E4D2C8CB91C115FB575D460ABBDAA6B982509547DB140C1C75AE82329`

Contract overlays remain metadata rather than being counted as implementations.
The complete archived V20 and V21 Go compiler graphs still fail native
compilation with exit 3. Their historical 10,186 global obligations have not
been recomputed or claimed discharged. Generic Go slices/aliasing/capacity,
interface type switches, the tagged value model, indirect closures and the
complete Go transpile CLI remain open. Linux/macOS roots retain previous status.
