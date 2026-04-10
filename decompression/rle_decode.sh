#!/bin/bash
# rle_decode.sh — binary-safe RLE decoder
# Reverses the [count][byte] encoding produced by rle_encode.sh.
# Usage: ./rle_decode.sh <input_file> <output_file>

set -euo pipefail
[[ ! -f "$1" ]] && { echo "Error: file not found: $1" >&2; exit 1; }

python3 - "$1" "$2" <<'EOF'
import sys

in_path, out_path = sys.argv[1], sys.argv[2]

with open(in_path, "rb") as fin, open(out_path, "wb") as fout:
    data = fin.read()
    if len(data) % 2 != 0:
        print("Error: corrupt RLE data (odd byte count)", file=sys.stderr)
        sys.exit(1)
    out = bytearray()
    for i in range(0, len(data), 2):
        count = data[i]
        byte  = data[i + 1]
        out.extend(bytes([byte]) * count)
    fout.write(out)
EOF
