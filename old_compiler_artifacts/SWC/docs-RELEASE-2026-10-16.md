# Windows SWC release evidence — 2026-10-16

Active executable: `../bin/swc.exe`, 228,352 bytes.
SHA256: `D2148E6C8B4EEB829B4F956AECD95F967E98DD2C4424C942211FE8082BD1D4F5`.
Active source: `../source/windows/se/swc-selfhost-windows.se`, 7,278,749 bytes.
SHA256: `AF18A2A4DF71AD90E9F0BEB5A74E5C290AC63EF436379B2132DDA6605AFDDD45`.

## Native runtime and repairs

- PEB module/export resolution and indirect Win64 calls with up to seven arguments.
- Native Windows allocation, file/standard-handle read/write/close, argv and exit.
- Zero import/bound-import/IAT/delay-import directories; zero PE overlay bytes.
- `.text` virtual bytes: 227,759; raw bytes: 227,840. The existing single-section
  layout is retained, including native literals; no separate data-section claim.
- Runtime label namespace moved beyond existing foreach-continue labels.
- CLI command initialization repaired; affected field ordering normalized for
  the bootstrap reader without activating unrelated dormant source functions.
- SMOD optional-flag out-of-bounds argv read and redundant compilation repaired.
- Manifest resolver supports Windows separators and drive-absolute unit paths.

Runtime machine-code templates are emitted by Semantic compiler functions.
They are not appended SE, an embedded EXE, a Go runtime or a subprocess.
Windows APIs are still required and are resolved dynamically; “import-free”
does not mean OS-independent. API-set namespace mapping is not implemented.

## Proof gates

The workspace Stage1/Stage2/Stage3 binaries have the executable hash above.
Both selfhost invocations used SMOD `--embed-all` and exited 0. Stage2 and
Stage3 independently passed all 38 checks in the native regression suite.
All 16 successful fixture PEs were checked for zero imports and zero overlays.
The repository-layout rebuild is recorded separately in
`repository-build-validation.json`; source hashes are checked before publishing.

Native checks cover tuple/binding/foreach/slice fixtures, argc/argv, redirected
version output, exact file bytes, default/explicit SMOD flags, spaced paths and
absolute unit paths. Four invalid fixtures reject with exit 3 and no EXE.
These results do not establish all variants of these families, all 82 UAST
kinds, full transpiler functionality, or Linux/macOS/cross-target revalidation.

## Reproduction

Run from the repository root with PowerShell 7:

```powershell
./crosscompiler/bin/swc.exe compile ./crosscompiler/manifests/swc.smod -o ./swc-rebuilt.exe --embed-all
./scripts/test-importfree-candidate.ps1 -Compiler ./crosscompiler/bin/swc.exe -FixtureDirectory ./crosscompiler/source/windows/se -OutputDirectory ./tmp/release-validation
# Optional PE inspection (Python is a diagnostic tool, not a compiler runtime):
python ./scripts/check-importfree-pe.py ./crosscompiler/bin/swc.exe
```

The previous checked-in Windows EXE is preserved under
`../../old_compiler_artifacts/SWC/bin/` if it was not already archived.
Historical reports and other platform artifacts are not deleted or rewritten.
