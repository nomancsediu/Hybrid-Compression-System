#!/bin/bash
# lzw_decode.sh — binary-safe LZW decoder
# Reads the packed big-endian 16-bit codes produced by lzw_encode.sh.
# Usage: ./lzw_decode.sh <input_file> <output_file>

set -euo pipefail
[[ ! -f "$1" ]] && { echo "Error: file not found: $1" >&2; exit 1; }

python3 - "$1" "$2" <<'EOF'
import sys, struct

in_path, out_path = sys.argv[1], sys.argv[2]

with open(in_path, "rb") as fin:
    raw = fin.read()

if len(raw) < 4:
    open(out_path, "wb").close()
    sys.exit(0)

count = struct.unpack_from(">I", raw, 0)[0]
expected = 4 + count * 2
if len(raw) < expected:
    print("Error: truncated LZW data", file=sys.stderr)
    sys.exit(1)

codes = struct.unpack_from(">" + "H" * count, raw, 4)

table = {i: bytes([i]) for i in range(256)}
next_code = 256

out = bytearray()
prev = table[codes[0]]
out.extend(prev)

for code in codes[1:]:
    if code in table:
        entry = table[code]
    elif code == next_code:
        entry = prev + prev[:1]
    else:
        print(f"Error: unknown LZW code {code}", file=sys.stderr)
        sys.exit(1)
    out.extend(entry)
    if next_code <= 65535:
        table[next_code] = prev + entry[:1]
        next_code += 1
    prev = entry

with open(out_path, "wb") as fout:
    fout.write(out)
EOF
