<!-- Copyright (c) 2026 Tarek Wasfy -->

# Semantic Programming Language — Example Programs

This collection contains small, progressive Semantic programs in readable and
prettified `.se` format. Each document is a standalone Semantic program and has
been validated with the current Semantic CLI.

## Beispiele

| File | Description |
| --- | --- |
| `01_hello_world.se` | Minimal program with text output |
| `02_variables_arithmetic.se` | Variables, integer values, and arithmetic |
| `03_conditionals.se` | Conditional execution with `if`/`else` |
| `04_loop_accumulator.se` | Loop and accumulated integer value |
| `05_functions.se` | Function with typed parameters and return value |
| `06_boolean_logic.se` | Boolean values and logical operators |
| `07_multiple_results.se` | Multiple return values and positional result extraction |
| `08_closure.se` | Closure with a captured environment |

## Verwendung

The Semantic Programming Language CLI can validate and format the files,
transpile them to Go, or build native output:

```text
Semantic Programming Language.exe semantic-validate 01_hello_world.se
Semantic Programming Language.exe semantic-format 01_hello_world.se -readable -o readable.se
Semantic Programming Language.exe semantic-transpile 01_hello_world.se -target go -o output.go
Semantic Programming Language.exe compile 01_hello_world.se -o example.exe
```

The compact `sp` alias is equivalent:

```text
Semantic Programming Language.exe sp semantic-validate 01_hello_world.se
```

The examples are intentionally small. Each demonstrates a clearly defined
Semantic/UAST capability and can be used as a regression test or as a starting
point for custom programs.
