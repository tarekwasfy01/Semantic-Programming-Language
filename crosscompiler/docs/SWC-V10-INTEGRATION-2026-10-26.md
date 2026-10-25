# SWC V10 integration

The V10 Semantic units originate from the user-supplied
`Semantic-Document-1-Compiler-Native-Code-V10-2026-10-25.zip`.
All 635 function bindings are imported with their internal graph relations,
transitive function dependencies and original contracts. The existing compiler
remains the compilation root. No second compiler, interpreter or source payload
is appended to the Windows executable.

## Native compiler changes

- The actual `fields.kind` reader recognizes `conditional` as native kind 27.
  Kind 23 retains its existing switch meaning.
- Conditional expressions use the existing x64 expression emitter, test,
  jumps, fixups and labels. The condition is evaluated once; only the selected
  branch executes and leaves its result in RAX.
- Missing condition, then or else relations produce a compilation error.
- V10 `less_equal`, `greater_equal` and unary `not` reuse the existing signed
  comparison and boolean-not emitters.
- Calls authored as statements are represented by `ExprStmt.expression`, so
  the real statement emitter executes them.
- The graph writer puts array terminators on separate lines. The importer
  reads metadata and extensions independently and rejects duplicate node IDs.

## Validation evidence

The retention audit preserves all 33,927 nodes and 44,117 relations of the
extended compiler basis. The merged graph contains 42,963 nodes and 635
additional function closures, with no missing bindings or unresolved callees.
An additional explicit call relation closes the newly authored node reader call.

The complete compiler candidate is 343,552 bytes. Its PE has no static import
directory and no overlay. Code and constants occupy the existing `.text`
section; this integration does not introduce separate `.rdata` or `.data`
sections.

Thirty-three native checks pass: 22 baseline comparisons, actual positive,
negative and zero `int_abs` calls, an inactive divide-by-zero branch, nine
family assertions across eleven original V10 functions, three operator aliases,
and three malformed-conditional rejection cases. These checks prove those
specific behaviors, not every input of every imported function.

The V10 library includes integer, lexer, graph-contract, layout, binary-format,
UTF-8 and machine-encoding helpers. Including those routines does not by itself
claim a complete Go-transpiler CLI or new target dispatch. The original archive's
reference-backend results are not used as proof of native SWC execution.

Selfhost activation and exact SHA256 values are recorded in the accompanying
`SWC-V10-VALIDATION-2026-10-26.json` after the SMOD build succeeds.
