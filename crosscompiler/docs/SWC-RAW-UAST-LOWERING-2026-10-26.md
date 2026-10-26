# Native source-UAST snapshot lowering

SWC now directly compiles the supplied V23 **source** UAST array, tuple,
index and explicit-copy slice functions. The source input is not rewritten by
Python or replaced with the previously supplied Core functions. The Semantic
reader records explicit type/effect contracts, and the native emitter emits
the guarded selection and slice bounds logic.

Supported here are immutable snapshots of one to five signed-i64 constants or
stable parameters, with explicit `return_minus_one` bounds policy and explicit
copy semantics for slices. The owning function must have one return statement;
its parameter names must be unique. Every symbolic operand must refer to one
of those parameters and carry the supplied stable-i64 proof. Assignments,
captures, shadowed/undeclared operands and other function-body shapes are
rejected by this specialized path. This limited ownership proof is not a
general language binding resolver.

For slices the emitted code checks `0 <= lo <= hi <= element_count`, then
`0 <= index < hi-lo`, before evaluating `lo+index`. Thus the i64 extreme-bound
tests do not overflow on an unguarded subtraction or addition. The value model
and index base must be explicit and zero-based. Missing source-level error
policy is rejected rather than silently treating a Go panic as a -1 result.

The recorded verification executes all 90 supplied V23 vectors and three additional
full signed-i64 cases over the original source-UAST function graphs. It
requires identical PE bytes with 1, 2 and automatic workers. Thirteen negative
cases cover effects, alias/snapshot flags, missing policy, wrong types,
undeclared/unstable/duplicate parameters, a valid parameter assignment and
missing copy semantics. Rejection must preserve an existing output file.

All input graph reads are immutable during parallel compilation. Ownership
checks run against the shared graph, while temporary stack slots and emitted
labels belong to each worker. Selection labels occupy `4096+13*N+5*id+j`,
where `N=max_node_id+1`; the table reserves 19 ranges to keep them separate
from existing conditional, loop, string, foreach and switch labels.

`manifests/uast-kinds.json` records all 109 structural kinds in the supplied
Semantic skill's canonical schema. `audit-uast.py` inventories an input graph
against that catalogue; it does not perform lowering or certify completeness.
`docs/UAST-LOWERING-INVENTORY.json` records the original frontend graph's
18,627 nodes across 19 observed kinds and the remaining proof obligations.
Type, effect, ABI and analysis kinds need semantic consumption; they are not
all standalone machine instructions.

The complete original frontend, generic memory/aliasing and lvalue semantics,
float/string/map/interface runtimes, general captures/dispatch, panic/cleanup,
channels/async and the other open catalogue families remain incomplete. The
historical global blocker count has not been recomputed or claimed resolved.
The pending V22 constant-index candidate remains separately unpromoted.

`docs/raw_uast_validation.json` and `docs/selfhost_validation.json`.
