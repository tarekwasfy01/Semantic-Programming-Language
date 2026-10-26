# Effectful tuple composition

The current SWC compiled `tests/matrix-tuple-effects-once.se` successfully.
Its PE executed and returned 24 as expected.

`tick(pointer,digit)` updates a nonescaping stack counter to
`old_counter * 10 + digit`, then returns that new value. Tuple element
ordinals call it with digits 1 and 2. Correct construction yields counter
12 and tuple `(1,12)`. The final result is `counter + product[2] = 24`.
This discriminates missing, duplicated and reversed calls for this case.

The recipe recovered in `lowering_recipes.json` records actual frame-depth
and store order from the existing emitter. It is an audit representation,
not a newly connected JSON execution engine. Its native evidence is
restricted to the tested stack-local eight-byte profile.

This improves semantic evidence, not the count of compiler implementations.
No new BindingPattern lowering is claimed.
