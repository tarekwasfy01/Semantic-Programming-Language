# Native typed Boolean lowering

SWC now lowers well-typed Rich Boolean operations directly to Windows x86-64:
`&&`, `||`, `!`, `==` and `!=`. No Python rewrite or reference backend is involved.
The implementation is part of `source/windows/se/swc-selfhost-windows.se`, with
its five helper closures mirrored in
`source/shared/se/units/swc-typed-boolean-native.se`.

## Meaning and eligibility

Rich operations require a Boolean result type, Boolean operand annotations and
an exact operator-confidence annotation. Boolean literals `true` and `false`
become Core integer values 1 and 0. Already encoded Boolean integer literals must
be exactly 0 or 1. The implementation also accepts the canonical typed semantic
identities `logical_and`, `logical_or` and `boolean_not`.

`&&` and `||` evaluate their left operand once and evaluate the right operand
only when required. They return a canonical 0/1 Boolean. `!` evaluates one
operand; Boolean equality/inequality evaluate their operands once, left first.
Labels are derived from expression IDs, so nested expressions and parallel
function scheduling do not change output bytes.

Canonical Core semantic IDs keep their existing meaning. A source-origin
`operator` spelling alongside `semantic_id: equal`, for example, does not turn
an existing integer comparison into a new Rich Boolean comparison.

The reader finds direct JSON object fields without matching nested fields or
escaped string contents. Current Boolean nodes may have effects before `kind`.
Original Rich right-child ordinal 0 becomes Core right-child ordinal 1;
`value` and `operand` unary edges map to the native operand role. This is an
incremental Boolean reader extension, not a replacement for the full parser.
Historical noncanonical projection records containing a redundant `fields.id`
retain their previous reader behavior.

## Native verification

The recorded verification executes 39 checks: 30 native program executions and nine
compile rejection cases. They cover complete truth tables, literal encoding,
nested operators, skipped divide-by-zero traps, and observable memory effects
that detect duplicate evaluations or incorrect left-to-right ordering.
The 13-function Boolean fixture produces identical bytes with 1, 2 and automatic
workers. Invalid types, approximate operators, missing/duplicate operands,
invalid literals and contradictory semantic identities are rejected while
preserving an existing output file.

The 24 V19/Core checks and seven previous parallel checks also pass. The current
selfhost has 1,712 functions and selects 12 workers on the validation host.
Hashes and final selfhost evidence are in `selfhost_validation.json`; individual
checks are in `boolean_validation.json`, `uast19_validation.json` and
`parallel_validation.json`.

Reproduce from the repository root:

```powershell
$env:SWC_THREADS = '0'
```

## Remaining scope

This proves a local lowering under declared Core Boolean type/ABI assumptions.
It does not implement whole-program Go type checking, dynamic Boolean truthiness,
the tagged dynamic value model, dynamic iterators or the complete Go frontend.
Unknown or mixed operand types are not silently specialized into this subset.
The full archived V19 Go frontend remains non-native-ready. Linux and macOS
compiler roots retain their previous status.

Later native integration: [V20 integer switches and V21 packed-byte subset](SWC-UAST-V20-V21-NATIVE-2026-10-26.md). General Go runtime limits above remain.
