#!/bin/bash
# smart_gzip_decompress.sh — full pipeline decompressor (GZIP → LZW → RLE)
# All .gz files produced by this tool are always RLE+LZW+GZIP encoded.
# Usage: ./smart_gzip_decompress.sh <input_file> <output_file>

set -euo pipefail

[[ "$#" -ne 2 ]] && { echo "Usage: $0 <input_file> <output_file>" >&2; exit 1; }

INPUT_FILE="$1"
OUTPUT_FILE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmp_gz="$(mktemp)"
tmp_lzw="$(mktemp)"
trap "rm -f '$tmp_gz' '$tmp_lzw'" EXIT

gunzip -c "$INPUT_FILE" > "$tmp_gz" || { echo "Error: GZIP decompression failed" >&2; exit 1; }
bash "${SCRIPT_DIR}/lzw_decode.sh" "$tmp_gz"  "$tmp_lzw"   || { echo "Error: LZW decode failed" >&2; exit 1; }
bash "${SCRIPT_DIR}/rle_decode.sh" "$tmp_lzw" "$OUTPUT_FILE" || { echo "Error: RLE decode failed" >&2; exit 1; }
