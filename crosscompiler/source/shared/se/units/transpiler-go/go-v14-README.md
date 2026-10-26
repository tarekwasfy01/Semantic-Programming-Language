# Semantic Document 1 – Go/Universal Primitives V14

This release adds **92 fully-bodied Core-SE functions** in **9 families** to the existing V13 compiler graph. Their bodies contain actual signed i64 operations and direct calls to other new functions. The original V13 functions remain intact (except the original `main` binding being renamed `compiler_v13_main` so the integrated entry calls both stages).

## Contents
- `core/Semantic Document 1.se`: combined V13 and new V14 compiler graph (`index_base=0`, `value_model=explicit`), with `ClosureExpr`, `ParameterDecl`, `CallExpr`, `syntax.child`, `semantic.call_target` and metadata contracts.
- `modules/<family>/<name>.se`: **92 individual transitively closed** executable SE modules, each with its full source body and closure + referenced dependencies.
- `contracts/Go-Primitive-Contract-Graph.se`: separate **contract overlay** with `ContractDecl` and `semantic.contract_for` edges to the executable closure IDs. This contract overlay is intentionally **not merged into the SWC-Core file**, because SWC compatibility for ContractDecl is not proven.
- `contracts/contracts.json`, `contract_edges.json`: contract predicates and exact closure IDs.
- `reports/call_graph.csv`, `primitive_contracts.csv`, `test_vectors.json`, `coverage.json`, `native_tests.json`.
- `native/`: importless Linux ELF binaries executed in test, plus an unexecuted structurally inspected standalone Windows PE. Combined Windows PE is blocked by the inherited >4-argument Win64 ABI emitter.
- `inputs/`: V13 base, attach tool and offline reference compiler sources for independent reproducibility.

## Verified results
- **304** input/output oracle vectors generated for all primitives and passed in independent expression evaluation.
- Standalone V14 generated ELF exit `0`; V13+V14 combined native ELF exit `203` (the original V13 value).
- 92 distinct primitive function bindings and arities checked; graph node IDs and explicit call targets validated. Standalone Windows PE import directory verified empty, **Windows executable NOT run**. Combined Windows PE was not emitted (legacy >4-param ABI blocker).
- No imports declared in the newly authored SE. Some original Rich Go runtime dependencies remain unresolved.

## Scope and contract limitations
- The original Go lexer/string runtime and full AST front-end are still NOT fully translated. Some guards are defined over restricted ASCII, token-class and i64 domains; contracts specify these restrictions and are not automatically enforced by the native compiler.
- The generated binaries use a **Python offline reference x86-64 emitter**, not a successful SWC native self-host rebuild. This is a standalone compiler feature-library extension, not proof of a complete compiler.
- The adjacent Rich contract overlay uses a non-executable `ContractDecl` form; only the Core-SE and its `extensions` metadata are presented to the reference backend.

## Rebuild
From the ZIP root, run `python3 build_go_primitive_contracts_v14.py`; files regenerate under `rebuilt_v14/`. The source repository is never modified.
