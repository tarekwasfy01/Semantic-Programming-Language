# SWC Windows active snapshot — 2026-10-25

## Published artifacts

| Existing repository path | Bytes | SHA-256 |
| --- | ---: | --- |
| `crosscompiler/bin/swc.exe` | 263,168 | `7FBFFF3558356830237416165F8E63CACA72A50EC47C81AE84F110EBFCFE1E0B` |
| `crosscompiler/source/windows/se/swc-selfhost-windows.se` | 8,548,075 | `7501FEF8D34BC6B5D8555D2090AE58F1B804B250C9F2296D0501356991ACB4EF` |

`crosscompiler/manifests/swc.smod` uses the existing repository-relative source path and contains the matching source SHA-256 and byte length. No files were moved or deleted; the existing repository structure is retained.

## Selfhost validation

Using the checked-in active executable and `--embed-all`:

- Stage 2: 263,168 bytes, SHA-256 `7FBFFF3558356830237416165F8E63CACA72A50EC47C81AE84F110EBFCFE1E0B`.
- Stage 3: 263,168 bytes, SHA-256 `7FBFFF3558356830237416165F8E63CACA72A50EC47C81AE84F110EBFCFE1E0B`.
- Stage 1, Stage 2, and Stage 3 hashes matched byte-for-byte.
- Stage 2 `version` returned exit code 0.

All generated executables were separate temporary outputs; the checked-in active executable remained unchanged. This proves this selfhost path only and does not establish complete support for every compiler primitive, UAST kind, or transpiler route.