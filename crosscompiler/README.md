# SWC crosscompiler

This directory keeps the Windows, Linux, and macOS crosscompiler sources and
artifacts in the existing repository layout. The current Windows snapshot is
dated 2026-10-25. Other platform artifacts were not changed in this update.

## Current Windows snapshot

- Executable: `bin/swc.exe` — 245,248 bytes, SHA-256
  `B0BF89D75BA534A523EF618D7E3A0BF6B4B1AC607409E710E699B2022CD59845`.
- Selfhost source: `source/windows/se/swc-selfhost-windows.se` — 8,042,865
  bytes, SHA-256
  `4CCDA4C54D6EE0D06AD31F1F03C0A52C6E62F9FCD77B2EE9871B6B09F02F0343`.
- Build manifest: `manifests/swc.smod`; it selects that source by a relative
  path and records its SHA-256 and byte length.
- Shared Semantic units and the transpiler matrix remain under their existing
  `source/shared/se/` paths. Their SE content did not change in this update.

## Build

From the repository root in PowerShell:

```powershell
./crosscompiler/bin/swc.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-rebuilt.exe --embed-all
```

The manifest is the build entry for the complete Windows Semantic source.
The checked-in executable is not replaced by this command.

## Verification boundary

Direct-SE Stage1/2/3 output was byte-identical to the checked-in executable.
The published relative-path `manifests/swc.smod` also produced byte-identical
Stage2/Stage3 output with `--embed-all`; see `docs/RELEASE-2026-10-25.md`.
Native fixtures covered signed division, remainder, return 42, tuple/index,
and BindingPattern. Invalid division type cases were rejected.

These checks do not prove that the previously observed intermittent access
violation is fixed, nor do they prove native execution for every UAST kind or
transpiler route. The dated reports document exact evidence and limitations.
