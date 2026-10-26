# Go Frontend Rich→Core V13 — source-derived lowerer

## Real results

* **5 functions** from the **original Rich Go front-end SE** lowered by traversing their actual `syntax.child` source graphs, not by writing replacement Go implementations.
* **600 semantic oracle checks** against an independent original-source switch-case walker, plus **51 additional native checks** of the ASCII→token-ABI bridge and original Go integer/comparison mapping.
* 1 standalone native ELF x64 test (exit `56`), and 1 merged **V12 parser + original Rich Core** native ELF test (exit `203`).
* Produced **191375 bytes x64 native code** for combined V12+RichCore reference ELF.
* Standalone native `semantic_document.v1` Core file, 5 individual `.se` modules and merged `compiler/core/Semantic Document 1.se` (also published with descriptive V13 name).

## Source semantics and ABI

The original Go functions operate on token strings or AST node types. The portable numeric-only Core backend cannot represent the full Go type system or arbitrary dynamic strings. This build uses a **closed-world i64 token-ID ABI**: every literal string and qualified Go token/type symbol appearing in the extracted functions receives a stable integer code (`reports/token_abi.json`). Empty string is code 0. Inputs and outputs are both encoded with the same mapping. Calls accepting arbitrary Go strings must first provide a real string→token bridge; this is **not** implemented or silently presumed. Switches/if statements/return values are converted to `ConditionalExpr`, `OperationExpr`, `LiteralExpr`, `SymbolRef`, `ReturnStmt`.

The source Rich files (`original-rich-units/`) are included for full traceability. `reports/source_trace.json` links every lowered function to its exact original closure ID.

## Limitations

This is an **incremental real Rich→Core lowering of selected source functions**, not full conversion of all 64 original Go-front-end closures. The 1,786 unresolved runtime/std library Go calls remain unresolved. No arbitrary Go AST, Go type checking, string runtime, memory objects, or imports have been implemented. A Windows PE file was produced and import headers inspected structurally, **not executed**. Tests use the existing Python-native reference compiler backend; **SWC self-host recompile is not established**. The actual original 64 functions are preserved separately, not replaced by a restricted TinyGo parser.

## Reproducibility

Run `python3 build_go_frontend_richcore_v13.py` from a directory that contains the original named V12 and frontend package folders. This regenerates the modules, links, test outputs and reports. The compiler sources and reference backend reside in the V12 package's `buildtools/`. If those are not available, use prebuilt SE documents directly, not a promise of rebuilding.
