# SWC Crosscompiler Working Tree

This directory is the reconstructed crosscompiler working tree.

## Validated compiler roots

- `bin/swc.exe` — native Windows Semantic selfhost, PE/EXE output.
- `bin/swc-windows-to-elf.exe` — Windows host with the recovered ELF backend.
- `bin/swc-linux.elf` — native Linux Semantic selfhost, ELF output.
- `bin/swc-linux-selfhost-pe.exe` — Linux host with the recovered PE backend.

All compiler inputs are Semantic/UAST sources. No Go host wrapper or external LLVM/linker is part of this tree.

## Reconstructed Windows to ELF proof

`bin/swc-windows-to-elf.exe` compiled `tests/return42.se` to `bin/return42-windows-to-elf.elf`.
The output is a 4,210-byte x86-64 ELF and returns exit code `42` under WSL.

## Source layout

- `source/windows/se/` — Windows/PE Semantic backend.
- `source/linux/selfhost/` — Linux/ELF Semantic selfhost.
- `source/shared/se/` — shared frontend, module, runtime, backend and transpiler units.
- `source/shared/modules/` — SMOD manifests and module dependencies.
- `manifests/` — target and cross-validation manifests.

The active repository `swc.exe` was not overwritten while reconstructing this tree.
