#!/bin/bash
# GZIP decompression script
# Reverses the compression pipeline: RLE -> LZW -> GZIP
# Decompression order: GZIP -> LZW decode -> RLE decode
# Usage: ./gzip_decompress.sh <input_file> <output_file>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

temp_gunzip="$(mktemp)"
temp_lzw_decoded="$(mktemp)"

# Step 1: Decompress GZIP
gunzip -c "$INPUT_FILE" > "$temp_gunzip"
if [[ $? -ne 0 ]]; then
    echo "Error: GZIP decompression failed" >&2
    rm -f "$temp_gunzip" "$temp_lzw_decoded"
    exit 1
fi

# Step 2: Decode LZW
bash "${SCRIPT_DIR}/lzw_decode.sh" "$temp_gunzip" "$temp_lzw_decoded"
if [[ $? -ne 0 ]]; then
    echo "Error: LZW decoding failed" >&2
    rm -f "$temp_gunzip" "$temp_lzw_decoded"
    exit 1
fi

# Step 3: Decode RLE
bash "${SCRIPT_DIR}/rle_decode.sh" "$temp_lzw_decoded" "$OUTPUT_FILE"
if [[ $? -ne 0 ]]; then
    echo "Error: RLE decoding failed" >&2
    rm -f "$temp_gunzip" "$temp_lzw_decoded"
    exit 1
fi

# Cleanup
rm -f "$temp_gunzip" "$temp_lzw_decoded"

echo "GZIP decompression complete: $OUTPUT_FILE"
