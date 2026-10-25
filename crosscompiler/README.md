# SWC crosscompiler

This directory contains the current Windows SWC snapshot in the repository's existing layout. The executable and Semantic source were copied from the active `mwsplc` root on 2026-10-25.

## Current Windows snapshot

- Executable: `bin/swc.exe` — 263,168 bytes, SHA-256 `7FBFFF3558356830237416165F8E63CACA72A50EC47C81AE84F110EBFCFE1E0B`.
- Selfhost source: `source/windows/se/swc-selfhost-windows.se` — 8,548,075 bytes, SHA-256 `7501FEF8D34BC6B5D8555D2090AE58F1B804B250C9F2296D0501356991ACB4EF`.
- Manifest: `manifests/swc.smod` selects that source using the existing repository-relative path and records the matching source hash and byte length.

## Build and selfhost check

From the repository root in PowerShell:

```powershell
./crosscompiler/bin/swc.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-stage2.exe --embed-all
./swc-stage2.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-stage3.exe --embed-all
```

The 2026-10-25 check produced Stage 2 and Stage 3 at 263,168 bytes each. Both SHA-256 values matched the checked-in executable: `7FBFFF3558356830237416165F8E63CACA72A50EC47C81AE84F110EBFCFE1E0B`. Stage 2 also returned 0 for `version`. Outputs were written separately; the checked-in executable was not overwritten during validation.

This proves the tested Stage2/Stage3 selfhost path for this snapshot. It does not claim complete support for every UAST kind, compiler primitive, or transpiler route.