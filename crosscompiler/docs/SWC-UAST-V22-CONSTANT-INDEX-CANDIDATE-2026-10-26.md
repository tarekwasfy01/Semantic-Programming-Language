# V22 constant-index candidate

An experimental Semantic compiler candidate handles constant reads from
explicitly immutable arrays and tuples whose elements are signed 64-bit
integer literals. It checks the explicit value model, zero-based indexing,
empty effects, type evidence, bounds, the 64-element limit and integer overflow.
It rejects dynamic indexes and copying slices in this candidate.

The candidate source is in `proof/v22/index-candidate.se`; the directly authored
helper functions are in `source/shared/se/units/swc-uast22-constant-index.se`.
It has not been promoted to the active compiler. Two candidate compiler
generations are byte-identical; selfhosting selected 12 workers for 1,728
functions, and all 165 existing regression checks passed. Execution of the
original source tests remains necessary to finish validation.

The original V22 tuple test executed and returned 8 with 1, 2 and automatic
workers; the three executables were byte-identical. Seventeen malformed and
unsupported inputs were rejected with compiler exit 3, while preserving an
existing output file. They include 65 elements, duplicate ordinals and invalid
or effectful elements that are not selected. Windows blocked the
generated original constant-array executable with a malware or potentially
unwanted software message, so that executable has not been run and its expected
exit 5 is not verified. `verify-uast22-index.ps1` records the intended full
verification and stops when Windows prevents execution.
Candidate evidence is in `uast22_index_candidate_validation.json`.
The independently runnable negative suite is `verify-uast22-index.ps1
-NegativeOnly`; its report is `uast22_index_negative_validation.json`.

The complete V22 semantics, dynamic indexing, copying slices and the general Go
frontend remain outside this candidate's proven coverage.
