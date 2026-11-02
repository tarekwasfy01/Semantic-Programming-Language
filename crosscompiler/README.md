# SWC crosscompiler

Current Windows selfhost status (2026-11-02): active SWC is the V45 multi-interface Semantic build. Stage2 and Stage3 built from the active manifest source are byte-identical; the active compiler's smoke output exits 42. Full UAST lowering, production E-Graph optimization, GPU kernels and the complete Go frontend remain incomplete.

- `bin/swc.exe`: 1,981,440 bytes; SHA-256 `06C8DEF92D9BDBCAA16C5E46B4EB1157E71F20C72F36840FDE15A94A3B2D269B`.
- Active source graph: `source/windows/se/swc-selfhost-windows-v45-multi-interface-active.se`; source SHA-256 `02785102E98EB0C34C026ACE11C0CC4364326E93BAD8BE64250B9C2F957A021B`. `manifests/swc.smod` names this exact source revision.
- Multi-interface UDP discovery finds the local worker on multiple interfaces. `SWCR1` has no stable worker identity, so duplicate endpoints for one worker are not safely deduplicated yet.
- **Cluster support is experimental.** Pairing/authentication and transfer of the exact compiler image and source snapshot reach the worker. The current active build has not delivered an `SFJ1` compiler job in the authenticated end-to-end test; remote compilation and result merging are therefore not yet validated for this build. Do not treat `--cluster=auto` as a working distributed compile path yet.
- The build still supports local compilation when no worker is found. Full UAST lowering, automatic native E-Graph optimization, OpenCL matrix/vector kernels and the complete Go frontend remain incomplete.

The experimental CLI surface is `cluster-pair`, `cluster-worker --cluster-listen`, `cluster-discover`, and `compile ... --cluster=auto`. For example:

```text
swc cluster-pair --cluster-pair-init --cluster-key cluster.key
swc cluster-worker --cluster-listen --cluster-port 24731 --cluster-key cluster.key
swc compile input.se -o input.exe --cluster=auto --cluster-port 24731 --cluster-key cluster.key
```

This command sequence currently demonstrates the interface only; the active-build test reached authenticated transfer but observed no compiler-job frame. Historical V35–V43 integration notes below describe earlier candidates and are not evidence that their behavior passes on the active V45 binary.

## V20/V21 native integration

Integer switches and their lexical control targets, seven V20 contracts, and the
20-function V21 packed-byte runtime are integrated directly in Semantic. Marked
Aggregate/Index/Slice/ForEach UAST nodes compile natively with automatic runtime
inclusion. All 321 build/run/rejection checks and 221 runtime vectors pass. See
[V20/V21 implementation and boundaries](docs/SWC-UAST-V20-V21-NATIVE-2026-10-26.md).

## Typed native Boolean lowering

Typed Rich `&&`, `||`, `!`, `==` and `!=` are compiled directly by SWC. Short
circuiting preserves left-to-right effects and evaluates operands once. All
39 Boolean, 24 V19/Core and seven parallel checks pass. See the
[Boolean implementation and evidence](docs/SWC-TYPED-BOOLEAN-NATIVE-2026-10-26.md)

## V19 native integration

V19 loop targets, closure boundaries, sparse statement ordering and six callable
contracts are integrated directly in Semantic. All 24 native V19/Core checks pass,
including nine rejection cases and deterministic parallel loop output. The full
archived Go frontend remains unsupported. See [V19 status](docs/SWC-UAST-V19-NATIVE-2026-10-26.md)

## Parallel compilation

Function compilation automatically uses the available logical processors, limited
by the number of functions and available worker memory. Workers claim functions
from an atomic queue. A parallel sizing pass and deterministic prefix sum assign
disjoint final code regions; a second parallel pass emits code at its real offsets.
Labels and relocations are then merged in function order. Reading, validation and
the final merge remain sequential.

## UAST-Diagnosen

`python crosscompiler/audit-uast.py <graph.se> --output <report.json> --strict-graph`
prüft doppelte Knoten-IDs, defekte Records und hängende Referenzen als Fehler.
Identische Kanten sowie mehrere `syntax.child`-Eltern werden mit Knoten-/Kanten-ID
als Warnung ausgegeben; allgemeine Mehrfachreferenzen werden als Information
ausgewiesen, weil graphweite Wiederverwendung zulässig sein kann. JSON-/Klammerfehler
enthalten Datei, Zeile, Spalte, Ausschnitt und Reparaturhinweis. Vollständige
Diagnosedetails stehen im JSON-Bericht; die Konsolenausgabe ist begrenzt.

The implementation is native Semantic in the complete selfhost graph and
[`swc-parallel-functions.se`](source/shared/se/units/swc-parallel-functions.se).
It requires no external worker program, Go runtime, Python runtime or build wrapper.
Windows thread callbacks use an explicit ABI adapter and checked native function
addresses. The existing Linux/macOS compiler roots are not changed by this update.

On the validation machine, the selfhost build selected 12 workers and reached
13 native threads including the main thread. Stage 1/2/3 are byte-identical.
See [implementation and evidence](docs/SWC-PARALLEL-FUNCTIONS-2026-10-26.md).

## Selfhost build



Generated executables and `validation.json` are saved in the ignored
`crosscompiler/proof/selfhost` directory. Both rebuilds can take several minutes.
The optional `scripts/build-current-state.ps1` runner performs the strict UAST
graph-integrity audit before starting those builds; that preflight requires Python.
It also sets `SWC_THREADS=0` and enables the parallel trace so every cache-miss
build uses the maximum available worker count and records the selection.

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






## UAST93 parameterized lowering reference

The UAST93 archive and checksum-verified extraction are preserved under `reference/source-archives/` and `reference/uast-v93/`. Its 15 new parameterized compile-time metadata witnesses are Linux GNU as/ld reference-backend results, not SWC-native lowerers. UAST93 itself reports 83 restricted witnesses but 0 kinds with complete semantics. See [UAST93-V39-IMPORT-STATUS-2026-10-28.md](docs/UAST93-V39-IMPORT-STATUS-2026-10-28.md) for scope and integration findings.


## Fail-closed native lowering

The fail-closed lowering edits remain in a separate source candidate; its `--embed-all` Stage 2 currently emits a PE but returns exit 3. The active V42-policy/V43-GPU-SE candidate passes byte-identical Stage2/Stage3 and the `return42` probe. E-Graph optimization is represented and selfhosted, but not yet connected to native `compile_expr`. See [SWC-FAIL-CLOSED-LOWERING-2026-10-28.md](docs/SWC-FAIL-CLOSED-LOWERING-2026-10-28.md).


## UAST94 composition reference

The UAST94 Linux reference archive and checksum-verified extraction are preserved under `reference/source-archives/` and `reference/uast-v94/`. It demonstrates restricted dynamic memory/composition witnesses, not SWC-native or complete UAST lowering. Unsupported-node rejection remains a known limitation in the active V42-policy/V43-GPU-SE compiler. See [UAST94-V35-IMPORT-STATUS-2026-10-28.md](docs/UAST94-V35-IMPORT-STATUS-2026-10-28.md).
