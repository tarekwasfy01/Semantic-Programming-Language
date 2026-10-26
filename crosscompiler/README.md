# SWC crosscompiler

Current Windows selfhost, validated 2026-10-26.

- `bin/swc.exe`: 407,552 bytes; SHA-256 `B37F784751F2909B357DD068F70598F3A26E839863B9AEDA30EDF1D0D921902A`.
- Complete source graph: `source/windows/se/swc-selfhost-windows.se`.
- `manifests/swc.smod` uses a repository-relative source path and its matching SHA-256.
- The active compiler, Stage 2 and Stage 3 reproduce the same bytes. The native return42 probe exits 42.
- The graph includes the V10 compiler closures, Go helper units V11-V16 and 19 V17 contract checker closures. Original Go helper units are stored with version prefixes in the existing `source/shared/se/units/transpiler-go` directory. Contract overlays are evidence, not executable implementations.
- Six already-lowered Core Boolean fixtures pass. Raw rich Boolean lowering and the Go transpile CLI remain incomplete.

## Reproduce from the repository root

```powershell
./crosscompiler/bin/swc.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-stage2.exe --embed-all
./swc-stage2.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-stage3.exe --embed-all
Get-FileHash ./crosscompiler/bin/swc.exe, ./swc-stage2.exe, ./swc-stage3.exe
```

All three hashes must match the hash above. Generated proof executables are temporary.

See [selfhost validation](docs/selfhost_validation.json), [current UAST status](docs/SWC-UAST-V17-V18-STATUS-2026-10-26.md), [Go helper integration and CLI limitations](docs/SWC-GO-FRONTEND-V11-V16-2026-10-26.md), and [native Core Boolean results](docs/SWC-UAST-V18-SWC-NATIVE-REPORT-2026-10-26.json).

Superseded Windows binaries, manifests, sources and historical crosscompiler documents are preserved in the existing `../old_compiler_artifacts/SWC` archive. Linux and macOS artifacts retain their previous validation status; this update validates the Windows selfhost only.
