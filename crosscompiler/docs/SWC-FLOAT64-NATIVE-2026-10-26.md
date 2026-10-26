# Native binary64 lowering in Windows Semantic SWC

The float path consumes explicit `type_ref.kind=float`, `bits=64` and
`ieee754=true` facts under the explicit value model. It supports finite decimal
literals, native `+`, `-`, `*`, `/`, unary negation, six ordered/unordered-aware
comparisons, typed scalar conditionals, and float values carried through the
compiler's internal scalar function ABI. Exact operation semantics are required.
Unsupported widths, missing type facts, unsafe mixtures, tagged values and
foreign floating-point call ABIs are rejected.

Values use the binary64 bit representation in existing scalar registers and
stack slots. Binary operators save the left operand before evaluating the
right one; native SSE2 instructions then operate on XMM0/XMM1. They support
negative zero, gradual underflow, infinities and NaNs produced by arithmetic.
NaN comparisons check the unordered flag explicitly: equality and ordered
comparisons are false; inequality is true. The backend uses the process's
default IEEE floating-point environment; alternative rounding/trap environments
and float-to-integer conversions are not claimed complete.

Decimal input is first checked against a complete bounded decimal grammar.
During the compiler's serial read phase, the Windows system `msvcrt.dll`
`sscanf` conversion produces the binary64 bits; `%n` verifies complete input
consumption. Overflow to infinity and textual NaN/Infinity are rejected as
literals. Scratch memory is released. The loaded system module/conversion
pointer is cached in main-context offsets 328/320 for the compiler-process
lifetime. Workers never read these slots; their context size stays unchanged.
Emitted programs contain immediate bits and SSE2 instructions and require no
CRT conversion routine for the implemented arithmetic.

The serial graph check rejects float values used as untyped integer arithmetic,
ordinary branch conditions or packed-byte elements. Internal named calls use
the established scalar ABI; the existing Win64 integer FFI is not silently
treated as an external XMM return/argument ABI.

Strict literal validation also exposed historical `value_type=boolean`
constants in the compiler source. Their explicit true/false forms are now
normalized to the Boolean representation, correcting the old `true`-as-zero
behavior. This is tested independently and may require a new compiler
generation before byte stability is reached.

`verify-float64.ps1` checks the original V22 float source tests, 59 independent
runtime assertions and malformed/type/ABI cases. The assertions compare exact
binary64 bit patterns, decimal and arithmetic rounding boundaries, subnormals,
signed zero, infinities, NaN on both sides of comparisons, canonical operation
precedence, lazy conditionals and exactly-once left-to-right operand effects.
Successful fixtures must reproduce identical bytes with 1, 2 and automatic
workers. Rejected inputs must preserve existing output files.

An additional 18-function fixture checks 16 results while emitting 129 native
float operations per arithmetic function. This exercises parallel sizing and
emission of substantial float bodies rather than only one large main function.
It also reproduces identical bytes across worker counts; 12 workers plus the
main thread were observed. Current machine evidence is in
`float64_validation.json` and `selfhost_validation.json`.

The complete UAST, type/binding analysis, typed heap layouts, strings/maps,
interfaces, captures, exceptions/cleanup and concurrency families still need
their corresponding native implementations; this float path is not a claim
of full source-language coverage.
