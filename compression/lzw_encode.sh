#!/bin/bash
# lzw_encode.sh — binary-safe LZW encoder
# Outputs packed big-endian 16-bit codes (max dict size 65535).
# Usage: ./lzw_encode.sh <input_file> <output_file>

set -euo pipefail
[[ ! -f "$1" ]] && { echo "Error: file not found: $1" >&2; exit 1; }

python3 - "$1" "$2" <<'EOF'
import sys, struct

in_path, out_path = sys.argv[1], sys.argv[2]

with open(in_path, "rb") as fin:
    data = fin.read()

# Build initial dictionary: single bytes 0-255
table = {bytes([i]): i for i in range(256)}
next_code = 256
MAX_CODE = 65535

codes = []
w = b""
for byte in data:
    c = bytes([byte])
    wc = w + c
    if wc in table:
        w = wc
    else:
        codes.append(table[w])
        if next_code <= MAX_CODE:
            table[wc] = next_code
            next_code += 1
        w = c
if w:
    codes.append(table[w])

with open(out_path, "wb") as fout:
    fout.write(struct.pack(">I", len(codes)))          # 4-byte count header
    fout.write(struct.pack(">" + "H" * len(codes), *codes))
EOF
