# Native direct-call evaluation order

The Windows Semantic compiler now evaluates ordinary named function-call
arguments once in source order, from left to right. It pushes each result and
then pops the arguments in reverse order into R9, R8, RCX, RDX, RSI and RDI as
applicable. The internal function ABI and six-argument limit stay the same.
Nested calls cannot overwrite earlier argument values because those values
remain on the runtime stack until all arguments have been evaluated.

This is a direct edit of `compile_expr` in
`source/windows/se/swc-selfhost-windows.se`: the argument loop starts at zero,
increments while below argc, and register-pop emission visits the six existing
register branches in reverse order. Both parallel sizing and emission passes
execute this same Semantic implementation. No new shared worker state is used.

Five independent fixtures exercise arities two through six. Each argument calls
a function that appends a digit to shared memory and returns that digit. The
callee separately combines its received parameter values. The tests check both
the memory history and parameter positions against explicit decimal constants.
The old compiler fails the six-argument fixture with exit 92: correct parameter
positions but reversed side effects. The corrected compiler returns 42.

`verify-call-order.ps1` builds and runs each fixture with 1, 2 and automatic
workers and requires identical executable bytes across these modes, for 15
checks. The fixtures contain three functions, so automatic mode is bounded by
that function count. Larger existing parallel fixtures exercise all host cores.

This change covers ordinary direct Semantic calls. Separate intrinsic emitters,
indirect closures, and the full Go frontend require their own coverage; this
change does not claim those paths complete.

Run from the repository root:

```powershell
./crosscompiler/verify-call-order.ps1
./crosscompiler/verify-selfhost.ps1
```

Machine-readable evidence is retained in `call_order_validation.json` and the
current `selfhost_validation.json`.
