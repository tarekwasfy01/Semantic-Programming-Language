# SWC crosscompiler

This directory keeps the Windows, Linux, and macOS crosscompiler sources and artifacts in the existing repository layout. The Windows snapshot was updated on 2026-10-25.

## Current Windows snapshot

- Executable: `bin/swc.exe` — 257,024 bytes, SHA-256 `ABC3FDFB3536438A46B0541F91A1AC599A61B7CA5D365AC8B364EBCECDADC626`.
- Selfhost source: `source/windows/se/swc-selfhost-windows.se` — 8,353,641 bytes, SHA-256 `B8A9C24E70C47CC293D1596D71390D2EA77EFA08A0E0CF5D0258AC2AD00901FE`.
- Build manifest: `manifests/swc.smod`; it selects that source by a relative path and records its SHA-256 and byte length.
- Shared Semantic units and the transpiler matrix remain under their existing `source/shared/se/` paths. Their contents were not changed in this update.

## Build

From the repository root in PowerShell:

```powershell
./crosscompiler/bin/swc.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-rebuilt.exe --embed-all
```

The checked-in executable is not replaced by this command.

## Verification boundary

Stage1, Stage2, Stage3, and the repository-relative SMOD `--embed-all` build were byte-identical. Nine native fixtures verified the specialized signed/unsigned division, shift, and comparison paths, including malformed-input rejection. The complete results are in `source/shared/se/transpiler-matrix/reports/specialized-binary-arity-20261025.json`; details are in `docs/RELEASE-2026-10-25.md`.

These checks do not prove complete support for every UAST kind, compiler primitive, or transpiler route.
