# V16 – Compiler capability expansion, not padding

## New functional coverage

- **51 real Core-SE closures** with executable expression trees, 115 independently stated expected outputs, contracts and exact resolved `semantic.call_target` relations. Each has a separate transitively closed .se file under `modules/`.
- Supports operator families needed to compile new Go subset syntax: `+ - * / %`, signed comparisons, bitwise `& | ^ &^`, booleans, and bounded nonnegative shifts. Every operation is lowered to actual SE expressions, not a placeholder intrinsic.
- `tools/compile_go_subset.py` is a deliberately **Python-hosted source parser** that compiles genuine, narrowly scoped Go source to the real SE closures. It creates executable native ELF plus experimental PE64, exercising the new SE functions. It is not the original complete Go frontend, not self-hosted and not SWC-tested.
- Supports Go source consisting of a package and one `func Value(args...) int|bool { ... }` with `return`, local declaration and `if ... else` returning expressions. No loops, pointers, strings, imports, struct, interfaces, floats, generics or multiple functions.
- `core/Semantic Document 1.se` is the V15 graph plus all V16 closures; original V15 function bodies are preserved.
- Contract preconditions are metadata and not automatically runtime-enforced. Shift functions are deliberately limited to nonnegative integers and shifts 0..31. Division by zero is rejected statically for immediate zero constants; dynamic zero divisors require caller contract enforcement.

## Testing / limits

- Native standalone ELF from graph-driven x86-64 reference backend executed with exit code 0.
- Generated Windows PE64 checked structurally but not executed. Entire V15+V16 Core compiles under reference backend and native ELF exits 203. Exact code-size change is in reports/size_delta.json.
- **SWC selfhost was NOT rebuilt.** Generated code size cannot be equated with increases of swc.exe.

## Build

```sh
python3 tools/compile_go_subset.py examples/arithmetic.go -o results/arithmetic --args 4,7
./results/arithmetic/out-linux-x64  # exit code 19
```
