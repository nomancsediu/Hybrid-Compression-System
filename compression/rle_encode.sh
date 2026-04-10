#!/bin/bash
# rle_encode.sh — binary-safe RLE encoder
# Encoding: each run is stored as 2 bytes: [count 1-255][byte]
# Single bytes with no run are stored as [1][byte].
# This is unambiguous and handles all byte values including digits and nulls.
# Usage: ./rle_encode.sh <input_file> <output_file>

set -euo pipefail
[[ ! -f "$1" ]] && { echo "Error: file not found: $1" >&2; exit 1; }

python3 - "$1" "$2" <<'EOF'
import sys

in_path, out_path = sys.argv[1], sys.argv[2]

with open(in_path, "rb") as fin, open(out_path, "wb") as fout:
    data = fin.read()
    if not data:
        sys.exit(0)
    i, n = 0, len(data)
    out = bytearray()
    while i < n:
        b = data[i]
        count = 1
        while count < 255 and i + count < n and data[i + count] == b:
            count += 1
        out.append(count)
        out.append(b)
        i += count
    fout.write(out)
EOF
