# SWC crosscompiler

The current Windows snapshot was updated on 2026-10-26 in the existing repository layout.

## Validated Windows build

- Executable: bin/swc.exe — 343,552 bytes, SHA256 ED889C815874AF4E057A959E6D9793E6A44D0520FB70E829FC202240757EDF5B.
- Source: source/windows/se/swc-selfhost-windows.se — 11175384 bytes, SHA256 0696AD18A1352831D428DDA9D7D3980634FFE8C8BEEC1091A36DCCEEA6C22996.
- Manifest: manifests/swc.smod selects the source with a repository-relative path and matching hash.
- All 635 V10 function closures are compiled into native code. Original units are grouped under source/shared/se/units/backend/v10.
- Stage 2 and Stage 3 are byte-identical; Stage 3 was built from SMOD with --embed-all.
- 33 native checks passed, including lazy conditional branches, V10 family calls, aliases, regressions and malformed-input rejection.
- The PE has no static import directory and no appended source payload. Code and constants use the existing .text section.

## Reproduce the selfhost

From the repository root in PowerShell:

    ./crosscompiler/bin/swc.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-stage2.exe --embed-all
    ./swc-stage2.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-stage3.exe --embed-all
    Get-FileHash ./swc-stage2.exe, ./swc-stage3.exe -Algorithm SHA256

Both generated files must match the executable hash above. Remove generated proof executables after checking them.

See [integration details](docs/SWC-V10-INTEGRATION-2026-10-26.md), [selfhost evidence](docs/SWC-V10-VALIDATION-2026-10-26.json), and [native checks](docs/SWC-V10-NATIVE-CHECKS-2026-10-26.json).

These results prove this Windows compiler snapshot and the tested inputs. They do not establish complete native coverage for every UAST kind or full Go-transpiler CLI parity. Linux and macOS artifacts retain their previous validation status.