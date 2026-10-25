# SWC crosscompiler

This directory keeps the Windows, Linux, and macOS crosscompiler sources and
artifacts in the existing repository layout. The current Windows snapshot is
dated 2026-10-25. Other platform artifacts were not changed in this update.

## Current Windows snapshot

- Executable: `bin/swc.exe` — 254,976 bytes, SHA-256
  `C9DE67E01A66B05C8ABFE1F0FD2EF1DDFB7142BB0E0E3B1A1F1B945D38A447CD`.
- Selfhost source: `source/windows/se/swc-selfhost-windows.se` — 8,364,732
  bytes, SHA-256
  `F15C9BAFD1B48B62150C33D4400F82EDEE816C621BFB79F19FE04C50E8A68CE8`.
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

Direct-SE Stage1/2/3 and the SMOD `--embed-all` build produced the same
SHA-256 as the checked-in executable. The staged repository-relative manifest
was rebuilt once with that executable and produced the same SHA-256; see
`docs/RELEASE-2026-10-25.md`.

Native fixtures covered return 42, BindingPattern, integer division, unsigned
comparison, and node-ID bounds. An out-of-capacity node ID was rejected without
an EXE. The SMOD arena regression compiled sparse node IDs through 599,185;
ID 599,186 was rejected without an EXE.

These checks do not prove native execution for every UAST kind or transpiler
route, nor absence of intermittent failures under other workloads.