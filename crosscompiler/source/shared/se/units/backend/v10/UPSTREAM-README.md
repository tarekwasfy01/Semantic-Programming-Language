# Semantic Document 1 Compiler V10 — DFA scanner + real ISA encoding

This extends V9 from **527 to 635 executable Core SE named `ClosureExpr` functions**, each with explicit contract, typed integer literal, named `ParameterDecl`, return-body and internally closed `semantic.call_target` edges. Adds **108** new routines: streaming numeric/identifier/JSON-string/comment DFA, structural SE/JSON-like quote-aware brace checking, checked digit accumulation, RISC-V 32-bit instruction field encoders, AArch64 32-bit instruction word encoders, COFF relocation/layout checks, and graph role discriminators.

There are **18 independently executed ELF native test binaries**, including real multi-character DFAs fed through nested SE calls, in addition to 28 streaming-language correctness oracles and 9 independent instruction-encoding oracles.

| Measure (same reference-native backend) | V9 | V10 | Increase |
|---|---:|---:|---:|
| Win64 generated machine-code bytes | 128980 | 161148 | **32168** |
| Linux generated machine-code bytes | 123945 | 154914 | **30969** |

## Contents
- `compiler/core/Semantic Document 1.se`: all 635 named closures, one reachable balanced dispatch, a native sample `main`
- `compiler/modules/*/*.se`: one *transitively closed* SE document per function; previous V9 527 units byte-identical
- `compiler/contracts.json` + `compiler/opcode_registry.csv`: group, signature, textual contract, closure dependencies
- `compiler/dfa_states.json`: state definitions
- `compiler/native/linux-x86_64/`: executable full dispatch ELF plus 18 tested ELF fixtures
- `compiler/native/windows-x86_64/`: experimental PE64 with static import directory zero
- `compiler/verification.json`, `compiler/verify.py`: reproducible test report
- `compiler/build_semantic_compiler_v10.py` + `compiler/buildtools/`: reproducible Linux generator, including all required V7/V8/V9 scripts and the V9 baseline

**Important:** We have NOT rebuilt the original 257024-byte `swc.exe`; SE source integration with its LFS Selfhost source, Rich→Core, and end-to-end COFF/PE linking remains. The generated PE is not Windows-runtime verified; native code measurements apply to a separate SE program compiled with a Python reference backend. Exact `.se` structure alone does not prove that SWC accepts every operation.
