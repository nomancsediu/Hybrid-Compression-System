#!/bin/bash
# compress.sh — RLE → LZW → GZIP pipeline with real progress feedback
# Usage: ./compress.sh <input_file> <output_file>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ ! -f "$1" ]] && {
    zenity --error --title="Error" --text="Input file not found:\n$1" --width=400
    exit 1
}

INPUT_FILE="$1"
OUTPUT_FILE="$2"

tmp_rle="$(mktemp)"
tmp_lzw="$(mktemp)"
trap "rm -f '$tmp_rle' '$tmp_lzw'" EXIT

# Run pipeline stages sequentially, piping progress updates to zenity
{
    echo "5";  echo "# Stage 1 of 3 — RLE encoding..."
    bash "${SCRIPT_DIR}/rle_encode.sh" "$INPUT_FILE" "$tmp_rle"

    echo "40"; echo "# Stage 2 of 3 — LZW encoding..."
    bash "${SCRIPT_DIR}/lzw_encode.sh" "$tmp_rle" "$tmp_lzw"

    echo "80"; echo "# Stage 3 of 3 — GZIP compression..."
    gzip -9 -c "$tmp_lzw" > "$OUTPUT_FILE"

    echo "100"; echo "# Done."
} | zenity --progress \
        --title="Compressing File" \
        --text="Please wait..." \
        --percentage=0 \
        --width=400 \
        --no-cancel \
        --auto-close 2>/dev/null

if [[ ! -f "$OUTPUT_FILE" ]] || [[ ! -s "$OUTPUT_FILE" ]]; then
    zenity --error --title="Error" --text="Compression failed: output file not created." --width=400
    exit 1
fi

ORIGINAL_SIZE="$(wc -c < "$INPUT_FILE")"
COMPRESSED_SIZE="$(wc -c < "$OUTPUT_FILE")"
RATIO="$(awk "BEGIN { printf \"%.1f\", (1 - ${COMPRESSED_SIZE}/${ORIGINAL_SIZE}) * 100 }")"

zenity --info \
    --title="Compression Complete" \
    --text="File compressed successfully.\n\nAlgorithm: RLE + LZW + GZIP\n\nOriginal Size:     ${ORIGINAL_SIZE} bytes\nCompressed Size:   ${COMPRESSED_SIZE} bytes\nCompression Ratio: ${RATIO}%" \
    --width=400 2>/dev/null
