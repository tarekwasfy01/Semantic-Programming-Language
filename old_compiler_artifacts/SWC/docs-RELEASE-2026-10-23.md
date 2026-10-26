# SWC crosscompiler snapshot — 2026-10-23

## Published artifacts to sync

| Existing repository path | Current bytes | SHA-256 |
| --- | ---: | --- |
| `bin/swc.exe` | 234,496 | `DCAF7908851E94C9F9E6A255725AC649F33A11C3C6082EFC9C1F2BE9E5365446` |
| `source/windows/se/swc-selfhost-windows.se` | 7,707,761 | `BDD02D5CAD98380E28547BBFD403677E8B34CA14D9FFD4A24EC369F493C8C00E` |

`manifests/swc.smod` is updated to reference the source above relative to the
manifest directory, with the same byte count and digest. No other platform
binary or source is changed by this Windows update.

## Validation performed for this sync

- `swc.exe version` reports `swc 2.3.2 windows-x64` (exit 0).
- `tests/return42.se` compiled with `--no-modules`; the generated 16,384-byte
  executable exited with code 42. The generated test executable was removed.
- Stage2 compiled the current source with `--embed-all`, returned exit 0, and
  produced a 234,496-byte executable whose SHA-256 equals the checked-in
  `swc.exe` hash above. Stage2 `version` returned successfully.
- Stage2 and Stage3 were rerun using the actual published manifest entry:
  `swc.exe compile manifests/swc.smod -o stage2.exe --embed-all`, then
  `stage2.exe compile manifests/swc.smod -o stage3.exe --embed-all`. Both
  returned exit 0 in 74.6 and 74.9 seconds. Both outputs were 234,496 bytes
  with SHA-256
  `DCAF7908851E94C9F9E6A255725AC649F33A11C3C6082EFC9C1F2BE9E5365446`, matching
  the checked-in compiler. The Stage2/Stage3 selfhost gate therefore **passes
  through the SMOD manifest path**.
- A separate direct-`.se` invocation from Stage2 crashed with
  `-1073741819` (`0xC0000005`). That is not the manifest build route and is
  retained here as a route-specific limitation, not misreported as a failed
  SMOD selfhost.
- The source tree contains 194 top-level shared unit files. 15 were absent from
  the published shared-units directory and 8 differed; those are synchronized
  in the existing unit directory. Existing grouped duplicates of those 8 units
  are updated in place, without adding directories. The transpiler matrix files
  already match and are not rewritten.
- Nested `source-contracts` material is not flattened or moved into the runtime
  unit directory. No compiler claims are inferred from those evidence files.

## Not claimed

- Successful direct-raw-SE Stage3 compilation; that alternate route crashed.
- Full native execution coverage for every UAST kind, transpiler route, or
  primitive.
- A fresh import-directory audit for this executable in this sync.
- Revalidation of Linux, macOS, or cross-target artifacts.

Historical validation remains in the existing dated reports and must be read
with its original source and executable hashes.
