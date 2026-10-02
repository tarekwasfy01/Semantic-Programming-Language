# macOS x86_64 Semantic crosscompiler

This directory is intended to live at `crosscompiler/source/mac/`.

The sources are single-layer Semantic compiler programs. They do not embed a second compiler/transpiler, Go wrapper, or external LLVM backend.

## Semantic sources

- `se/SLC-macOS-x86_64-Selfhost.se` — macOS/Darling x86_64 host → Mach-O x86_64 target.
- `se/SLC-macOS-to-Linux-ELF.se` — macOS/Darling x86_64 host → Linux ELF64 x86_64 target.
- `se/SLC-macOS-to-Windows-PE64.se` — macOS/Darling x86_64 host → Windows PE32+ x86_64 target.

## Matching repository binaries

The corresponding bootstrapped Mach-O compilers are placed in the repository-level `crosscompiler/bin/` directory:

- `SLC-macOS-x86_64`
- `SLC-macOS-to-Linux-ELF`
- `SLC-macOS-to-Windows-PE64`

## Current validation

- All three compiler binaries are Mach-O 64-bit x86_64 executables.
- Mac→Linux target logic produced a valid ELF64 x86_64 `return42` proof image.
- Mac→Windows target logic produced a valid PE32+ x86_64 `return42.exe` proof image.
- The two cross-target compiler builds were reproduced byte-identically from their Semantic sources.
- Mach-O images contain the expected `LC_MAIN`, dyld/libSystem linkage, and `__TEXT.__text` layout.

See `proof/` for validation details and `verify-under-darling.sh` for the intended Darling Stage2/Stage3 test.

## Darling note

The current execution sandbox blocks Darling's required UTS/IPC namespace setup (`unshare` returns `Operation not permitted`). Therefore the final runtime Stage2→Stage3 invocation must be executed on a namespace-capable Darling host. This is an environment limitation, not a structural Mach-O validation failure.
