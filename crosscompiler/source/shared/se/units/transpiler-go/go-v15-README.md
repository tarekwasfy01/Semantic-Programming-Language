# Semantic Document 1 — V15 Go Frontend Primitives, Contracts & Closures

**Actual implementation**: 75 new source-authored `semantic_document.v1` Core closures in 5 families, each with real expression body, explicit parameters, graph edges, `semantic.call_target`, and a contract. The 75 individual `.se` modules include all transitive V15 dependencies (not dangling declarations).

## Changes versus V14
- Extended Go numeral decoding (radix/prefix, bounded decimal helpers), strict UTF-8 (overlong, surrogates, limit U+10FFFF), Pratt operator precedence and delimiter state, Core-UAST structural constraints, COFF/PE and rel32 alignment guards.
- Fixed the **reference x86-64 emitter's Win64 calling convention for 5–6 arguments**, saving register and stack arguments with correct 32-byte shadow space and stack alignment. The patched emitter is in this generator; it does not modify SWC or its selfhost source.
- Combined `core/Semantic Document 1.se` preserves original V14 bodies and adds the new connected closures and a `main` entry. Separate `contracts/Contract-Overlay.se` uses `ContractDecl` and `semantic.contract_for` and is NOT compiled by the reference emitter; contract metadata is also embedded within Core SE extensions.

## Verified locally
- 268 interpreter checks and 15 independent fixed golden cases.
- Standalone Linux ELF exit 0; integrated V14+V15 Linux ELF exit 203.
- Win64-convention machine code **actually executed under Linux using an ELF entry trampoline**, exit 0 standalone and 203 integrated. A specific 5+6 arg regression returned exit 67 as expected.
- The combined Windows PE was generated and the import directory checked empty, but **it has NOT been executed on Windows or Wine**.
- Core graph node references, duplicate closure identities, local `semantic.call_target` relations and contract links checked.
- Rebuild offline from unpacked ZIP with `python3 build_go_primitives_v15.py` (writes `rebuilt_v15`). Contains V14 source snapshot plus offline code generator.

## Limits
- **Not SWC selfhost tested**. `.se` functions in this package were compiled using the Python reference backend.
- The full original Go typechecker, syntax tree conversion, runtime and unresolved rich calls remain open; this improves the Go-frontend support code and core transport but is not a full compiler.
- Guards have explicit bounded integer/ASCII/UTF-8 contracts. The native emitter does not automatically enforce preconditions: invalid inputs are only characterized where the function body explicitly returns a sentinel.
- No DLL imports are declared in new SE. Empty import tables in generated PE files do not prove a complete host-free runtime.
