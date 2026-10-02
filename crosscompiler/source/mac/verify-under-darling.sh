#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
BIN_DIR="${BIN_DIR:-$HERE/bin}"
OUT="${OUT:-/tmp/slc-mac-proof}"
mkdir -p "$OUT"

host_path() { printf '/Volumes/SystemRoot%s' "$1"; }

SELF="$BIN_DIR/SLC-macOS-x86_64"
LNX="$BIN_DIR/SLC-macOS-to-Linux-ELF"
WIN="$BIN_DIR/SLC-macOS-to-Windows-PE64"
SRC_SELF="$HERE/se/SLC-macOS-x86_64-Selfhost.se"
TEST="$HERE/tests/return42.se"

for f in "$SELF" "$LNX" "$WIN" "$SRC_SELF" "$TEST"; do
  test -f "$f" || { echo "missing: $f" >&2; exit 2; }
done

# stage2 and stage3 selfhost
DARLING_SELF="$(host_path "$SELF")"
DARLING_SRC="$(host_path "$SRC_SELF")"
DARLING_S2="$(host_path "$OUT/stage2")"
DARLING_S3="$(host_path "$OUT/stage3")"
darling shell "$DARLING_SELF" compile "$DARLING_SRC" -o "$DARLING_S2"
darling shell "$DARLING_S2" compile "$DARLING_SRC" -o "$DARLING_S3"
cmp -s "$OUT/stage2" "$OUT/stage3"
echo "macOS selfhost stage2=stage3: PASS"

# Mac -> Linux
DARLING_LNX="$(host_path "$LNX")"
DARLING_TEST="$(host_path "$TEST")"
DARLING_LNX_OUT="$(host_path "$OUT/return42-linux.elf")"
darling shell "$DARLING_LNX" compile "$DARLING_TEST" -o "$DARLING_LNX_OUT"
chmod +x "$OUT/return42-linux.elf"
set +e
"$OUT/return42-linux.elf"
rc=$?
set -e
test "$rc" -eq 42
echo "macOS -> Linux return42: PASS"

# Mac -> Windows
DARLING_WIN="$(host_path "$WIN")"
DARLING_WIN_OUT="$(host_path "$OUT/return42-windows.exe")"
darling shell "$DARLING_WIN" compile "$DARLING_TEST" -o "$DARLING_WIN_OUT"
python3 - "$OUT/return42-windows.exe" <<'PY'
import struct,sys
p=sys.argv[1]
b=open(p,'rb').read()
assert b[:2]==b'MZ'
off=struct.unpack_from('<I',b,0x3c)[0]
assert b[off:off+4]==b'PE\0\0'
print('macOS -> Windows PE64 headers: PASS')
PY

sha256sum "$OUT/stage2" "$OUT/stage3" "$OUT/return42-linux.elf" "$OUT/return42-windows.exe"
