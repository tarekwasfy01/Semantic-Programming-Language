# SWC crosscompiler

This directory keeps the Windows, Linux, and macOS crosscompiler sources and
artifacts in the existing repository layout. The current Windows snapshot is
dated 2026-10-23.

## Current Windows snapshot

- Executable: `bin/swc.exe` — 234,496 bytes, SHA-256
  `DCAF7908851E94C9F9E6A255725AC649F33A11C3C6082EFC9C1F2BE9E5365446`.
- Selfhost source: `source/windows/se/swc-selfhost-windows.se` — 7,707,761
  bytes, SHA-256
  `BDD02D5CAD98380E28547BBFD403677E8B34CA14D9FFD4A24EC369F493C8C00E`.
- Build manifest: `manifests/swc.smod`; it selects that source by a relative
  path and records its SHA-256 and byte length.
- Shared Semantic units and the transpiler matrix remain under their existing
  `source/shared/se/` paths. This snapshot updates existing unit files and adds
  missing units only inside the existing `units/` directory; it creates no new
  directory tree.

## Build

From the repository root in PowerShell:

```powershell
./crosscompiler/bin/swc.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-rebuilt.exe --embed-all
```

The manifest is the build entry for the complete Windows Semantic source.
The checked-in executable is not replaced by this command.

## Verification boundary for this snapshot

On 2026-10-23, `swc.exe version` returned `swc 2.3.2 windows-x64`. The native
`return42.se` fixture compiled and exited with code 42. Stage2 and Stage3 both
compiled the current `manifests/swc.smod` with `--embed-all`, exited 0, and
produced byte-identical 234,496-byte executables matching the checked-in
compiler SHA-256. The full manifest-based Stage2/Stage3 selfhost gate passes.
The direct raw-`.se` invocation is not the validated build route; its Stage3
attempt crashed. See `docs/RELEASE-2026-10-23.md` for exact commands and hashes.

The dated reports from 2026-10-16 remain historical evidence and are not
silently presented as fresh test results for this newer source snapshot.
