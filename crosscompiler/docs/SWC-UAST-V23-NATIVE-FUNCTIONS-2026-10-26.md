# V23 lowered Semantic functions in Windows SWC

The Windows compiler links the ten V23 lowered Core functions
`u23_array_runtime_1..5`, `u23_tuple_runtime_2..4`, and
`u23_slice_runtime_2..3`, plus `u23_group_selftest`. These functions implement
bounded immutable scalar snapshots; slices use copy semantics, and invalid
indices return -1. They are not general Go slice or panic semantics.

The native reader recognizes `ConditionalExpr` nodes in the V23 Core forms
`uast23.snapshot_index_read` and `uast23.snapshot_slice_read` even when their
metadata precedes `kind`. This correction matters: the previous compiler
accepted the unmodified V23 smoke program but it returned 216 rather than the
expected zero. Existing conditional emission evaluates only the selected arm.

The original Core smoke program and a separate assertion program are compiled
and executed with 1, 2 and automatic workers. Each output must be byte-identical
across modes. The assertion program compares all 90 supplied vector expectations,
three additional full signed-i64 boundary cases and the supplied group selftest.
These assertions are counted separately from build/execution checks.

The archive's lowerer for arbitrary source UAST is not embedded. Parameter
ownership, purity, snapshot and copy proofs must still be established by a
future native lowering pass; linking the already lowered functions does not
prove the general original Go frontend or full UAST lowering. The pending V22
constant-index candidate remains separate because Windows blocked its original
array-test executable.

Archive SHA-256:
`07C576F30B8D412CDC6D54BF8751CCC1EC0C1FBAC18404FCB5DB10862B314546`.
