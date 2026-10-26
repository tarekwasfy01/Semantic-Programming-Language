# SWC crosscompiler

Current Windows selfhost with native parallel compilation, typed Booleans, V20 switches and V21 packed-byte lowering, validated 2026-10-26.

- `bin/swc.exe`: 719,360 bytes; SHA-256 `C2C423D5F0E45501DDB33FC4A0C7CFDCB75CBA2236BEC203CA45CCBE317B47BA`.
- Complete source graph: `source/windows/se/swc-selfhost-windows.se`.
- `manifests/swc.smod` uses a repository-relative source path and its matching SHA-256.
- The active compiler, Stage 2 and Stage 3 reproduce the same bytes. The native return42 probe exits 42.
- The graph includes the V10 compiler closures, Go helper units V11-V16 and 19 V17 contract checker closures. Original Go helper units are stored with version prefixes in the existing `source/shared/se/units/transpiler-go` directory. Contract overlays are evidence, not executable implementations.
- Earlier V17 validation records six passing Core Boolean fixtures. Typed Rich Boolean operators now lower natively with 39 passing Boolean checks. The complete Go frontend and Go transpile CLI remain incomplete.

## V20/V21 native integration

Integer switches and their lexical control targets, seven V20 contracts, and the
20-function V21 packed-byte runtime are integrated directly in Semantic. Marked
Aggregate/Index/Slice/ForEach UAST nodes compile natively with automatic runtime
inclusion. All 321 build/run/rejection checks and 221 runtime vectors pass. See
[V20/V21 implementation and boundaries](docs/SWC-UAST-V20-V21-NATIVE-2026-10-26.md).
Run `./crosscompiler/verify-uast20.ps1` and `./crosscompiler/verify-uast21.ps1`.

## Typed native Boolean lowering

Typed Rich `&&`, `||`, `!`, `==` and `!=` are compiled directly by SWC. Short
circuiting preserves left-to-right effects and evaluates operands once. All
39 Boolean, 24 V19/Core and seven parallel checks pass. See the
[Boolean implementation and evidence](docs/SWC-TYPED-BOOLEAN-NATIVE-2026-10-26.md)
and run `./crosscompiler/verify-boolean.ps1`.

## V19 native integration

V19 loop targets, closure boundaries, sparse statement ordering and six callable
contracts are integrated directly in Semantic. All 24 native V19/Core checks pass,
including nine rejection cases and deterministic parallel loop output. The full
archived Go frontend remains unsupported. See [V19 status](docs/SWC-UAST-V19-NATIVE-2026-10-26.md)
and run `./crosscompiler/verify-uast19.ps1`.

## Parallel compilation

Function compilation automatically uses the available logical processors, limited
by the number of functions and available worker memory. Workers claim functions
from an atomic queue. A parallel sizing pass and deterministic prefix sum assign
disjoint final code regions; a second parallel pass emits code at its real offsets.
Labels and relocations are then merged in function order. Reading, validation and
the final merge remain sequential.

The implementation is native Semantic in the complete selfhost graph and
[`swc-parallel-functions.se`](source/shared/se/units/swc-parallel-functions.se).
It requires no external worker program, Go runtime, Python runtime or build wrapper.
Windows thread callbacks use an explicit ABI adapter and checked native function
addresses. The existing Linux/macOS compiler roots are not changed by this update.

Optional PowerShell controls:

```powershell
$env:SWC_THREADS = '0'          # Automatic; also the default when unset
$env:SWC_THREADS = '1'          # Serial reference compilation
$env:SWC_THREADS = '4'          # At most four workers
$env:SWC_PARALLEL_TRACE = '1'   # Print the selected worker/function counts
./crosscompiler/verify-parallel.ps1
```

On the validation machine, the selfhost build selected 12 workers and reached
13 native threads including the main thread. Stage 1/2/3 are byte-identical.
See [implementation and evidence](docs/SWC-PARALLEL-FUNCTIONS-2026-10-26.md).

## Reproduce from the repository root

Run the local verification script to rebuild both stages, compare their hashes,
and compile and execute return42 with Stage 3:

```powershell
./crosscompiler/verify-selfhost.ps1
```

Generated executables and `validation.json` are saved in the ignored
`crosscompiler/proof/selfhost` directory. Both rebuilds can take several minutes.

The equivalent manual build commands are:

```powershell
./crosscompiler/bin/swc.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-stage2.exe --embed-all
./swc-stage2.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-stage3.exe --embed-all
Get-FileHash ./crosscompiler/bin/swc.exe, ./swc-stage2.exe, ./swc-stage3.exe
```

All three hashes must match the hash above. Generated proof executables are temporary.

See [selfhost validation](docs/selfhost_validation.json), [parallel validation](docs/parallel_validation.json), [UAST status](docs/SWC-UAST-V17-V18-STATUS-2026-10-26.md), [Go helper integration and CLI limitations](docs/SWC-GO-FRONTEND-V11-V16-2026-10-26.md), and [native Core Boolean results](docs/SWC-UAST-V18-SWC-NATIVE-REPORT-2026-10-26.json).

Earlier Windows binaries, manifests, sources and historical crosscompiler documents are preserved in the existing `../old_compiler_artifacts/SWC` archive. Linux and macOS artifacts retain their previous validation status; this update validates the Windows selfhost only.

Ordinary direct calls now evaluate arguments left to right; see [call-order evidence](docs/SWC-CALL-ORDER-2026-10-26.md).

Six V22 selector closures are integrated; raw V22 lowering remains incomplete. See [V22 selector status](docs/SWC-UAST-V22-SELECTORS-2026-10-26.md).

Explicit zero-represented 64-bit V22 pointer nil is handled natively. See [pointer-null status](docs/SWC-UAST-V22-POINTER-NULL-2026-10-26.md).

Eleven V23 lowered Core functions and the V23 conditional reader are integrated; source-UAST lowering remains incomplete. See [V23 status](docs/SWC-UAST-V23-NATIVE-FUNCTIONS-2026-10-26.md).

SWC now directly compiles original V23 source-UAST snapshots (arrays, tuples, checked indices and explicit-copy slices); 93 source assertions pass. The full 109-kind catalogue is inventoried, with general coverage still incomplete. See [native raw UAST status](docs/SWC-RAW-UAST-LOWERING-2026-10-26.md).

Explicit binary64 literals, arithmetic, comparisons and internal scalar calls now lower natively to SSE2. The float matrix has 59 assertions plus 16 parallel function-result assertions. See [native float64 status](docs/SWC-FLOAT64-NATIVE-2026-10-26.md).

V24 heap-backed arrays and alias-preserving slice reads/writes now compile natively on Windows. See [V24 implementation](docs/SWC-UAST-V24-HEAP-NATIVE-2026-10-26.md).
