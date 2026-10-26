# Native Semantic parallel function compiler

The active Windows SWC compiles functions concurrently by default. Its executable
is 700,416 bytes with SHA-256
`41F9EB35324A72FBAB0A191B2A1A836976D6B72D68864D9C025BC5DEBA2A49A1`.
The complete Semantic source is `source/windows/se/swc-selfhost-windows.se`,
SHA-256 `84266FC131AB99752A9F74783D87D53F8281BD70DB51358385598EB7FCCA1730`.
The repository-relative manifest is `manifests/swc.smod`.

## Execution and determinism

1. The existing reader and validation scan construct the immutable program graph.
2. A task record is created for each function, in ascending Semantic node order.
   Workers claim tasks with an aligned 64-bit `LOCK XADD` counter.
3. A sizing pass runs the real function compiler with output writes suppressed.
   It records each function's code size, label count and relocation count.
4. A sequential prefix sum assigns exact final code regions and bounded log
   regions. This preserves position-dependent Win64 instruction displacements.
5. Workers compile functions into disjoint regions of the final image. Each
   worker owns its compiler context, local slots, error state and control state.
   Each task owns its label and relocation records. Input graph storage is shared
   read-only. Measured code and log bounds are enforced during emission.
6. All workers are joined. Their records are merged in function order; relocation
   resolution and PE completion follow the existing path. Failed compilation
   returns before the output file is written.

Function sizes and records are independent of task scheduling. The sequential
parser, prefix sum and final merge are dependencies of the parallel phases;
the implementation does not claim continuous full CPU utilization in those phases.

## Native runtime and ABI

All implementation code is Semantic. The complete selfhost graph contains the
worker runtime plus changes to `compile_program`, `compile_expr`, `emit8`,
`patch32`, `fix_add` and `label_set`. The helper closures are also retained in
`source/shared/se/units/swc-parallel-functions.se`.

Windows APIs are resolved through the existing PEB export resolver. Worker entry
uses a Win64-to-Semantic integer ABI thunk: RCX becomes RDI, RDI/RSI are preserved,
and the stack is aligned. The thunk and queue primitive are written to a writable
page, changed to executable/read-only, and passed to `FlushInstructionCache` before
threads start. They are released after the workers finish.

`ifree_function_address(function_symbol)` is a new backend intrinsic. It requires
exactly one named function reference, resolves the function during compilation,
and emits RIP-relative address materialization with a normal relocation.
Unknown functions, non-reference arguments and wrong arity are rejected.
The resulting pointer uses Semantic's internal ABI; the pool's Win64 callback
adapter supplies the required Windows ABI conversion. The closure importer accepts
the intrinsic only when the core `compile_expr` actually dispatches to its handler.

Automatic worker count uses `GetActiveProcessorCount`, bounded by task count.
If worker slot allocation fails, the count is reduced. If parallel setup cannot
be completed safely, compilation uses the serial implementation. A failed thread
creation runs that worker's queue consumer inline. A failed join or worker aborts
compilation without publishing output; live worker storage is retained until
process termination rather than freed underneath a thread.

Internal layout is documented at the top of the helper `.se` unit. A worker uses
a 512-byte record, a private compiler context at byte 128 and 8 MiB of slot storage.
Task records are 64 bytes; label and relocation records are 16 bytes. Context byte
240 selects serial, sizing or bounded emission mode. No separate compiler process,
external runtime or shell wrapper performs the parallel work.

## Controls and reproduction

Normal `swc compile ...` commands select workers automatically. `SWC_THREADS=1`
selects the serial reference path; a larger positive value limits the workers.
Unset or zero selects the available logical processors. `SWC_PARALLEL_TRACE=1`
prints the selected worker count, function count and two-pass mode.

From the repository root:

```powershell
./crosscompiler/verify-parallel.ps1
./crosscompiler/verify-selfhost.ps1
```

The scripts write executables and JSON reports under the ignored
`crosscompiler/proof/` directory. The active complete graph and native executable
are sufficient to reproduce the build; no Python or Go compilation step is needed.

## Native evidence, 2026-10-26

- The current 1,751-function selfhost selected 12 workers on this host. A runtime assertion
  compilation was observed with 13 native threads including the main thread.
- Before V19, the 1,657-function Stage 2 took 57.23 seconds and Stage 3 took
  61.78 seconds. These historical timings describe the earlier parallel build.
  These are measurements of this machine/run, not a general speedup guarantee.
- Stage 1, Stage 2 and Stage 3 have the same SHA-256 above. Stage 3 freshly compiled
  `return42.se`, whose native output exited 42.
- A 67-function fixture covers cross-function calls, loop and branch labels,
  parameters, local slots and string relocation. Serial, two-worker and automatic
  builds all produce SHA-256
  `64B706EBC8C8C366695D8EEFD819710070846A5B29D7BF773B7F4A7D3AA7EF40`;
  each native program exits 44.
- A native function-address fixture exits 42. Missing targets and wrong arity
  return compiler exit 3 without creating output. A failing task among the
  67 functions returns 3 and preserves an existing output file byte-for-byte.
- The helper import has no missing bindings or unresolved transitive callees.

See `selfhost_validation.json` and `parallel_validation.json` for machine-readable
results. This changes the Windows compiler root. Linux/macOS validation and complete Go frontend limitations retain their previous
status. Typed Rich Boolean lowering is now native; see the
[Boolean status](SWC-TYPED-BOOLEAN-NATIVE-2026-10-26.md).

The active build also includes [V19 native loop integration](SWC-UAST-V19-NATIVE-2026-10-26.md).

The current source also includes [V20 switches and V21 packed-byte lowering](SWC-UAST-V20-V21-NATIVE-2026-10-26.md).
