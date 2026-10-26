# V22 explicit pointer-null lowering

The native Windows Semantic compiler handles the V22 `NilLiteral` form whose
literal kind is explicitly accompanied by a `pointer` type of exactly 64 bits,
the `uast22_null_abi` value `zero_pointer`, no effects, zero-based indexing and
the explicit value model. It emits the integer representation zero. A V22
literal nil that lacks these proofs is rejected, including interface nil, a
different pointer width, an effectful literal, tagged values or a missing ABI.
Older compiler-internal `kind=nil` records keep their existing handling.

The source reader checks these properties before parallel worker execution.
Workers receive the existing immutable graph and emit the proven zero value
using their own context. No new worker state or runtime dependency is needed.

The original supplied V22 pointer-null program and independent malformed
variants are tested by `verify-uast22-null.ps1`. Successful compilation is run
with 1, 2 and automatic workers and compared byte for byte. Rejected programs
must return compiler error 3 without overwriting an existing output file.

This handles only the explicit zero-pointer representation. General Go nil,
interfaces, maps and slices need their own representation and runtime rules;
the remaining V22 array, tuple, float and string lowering also remains open.
