#!/bin/bash
# decompress.sh — orchestrates decompression with progress UI
# Usage: ./decompress.sh <input_file> <output_file>

set -euo pipefail

[[ "$#" -ne 2 ]] && { echo "Usage: $0 <input_file> <output_file>" >&2; exit 1; }

INPUT_FILE="$1"
OUTPUT_FILE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ ! -f "$INPUT_FILE" ]] && {
    zenity --error --title="Error" --text="File not found:\n${INPUT_FILE}" --width=400
    exit 1
}

(
    echo "10"; echo "# Stage 1 of 3 — GZIP decompression..."
    echo "40"; echo "# Stage 2 of 3 — LZW decoding..."
    echo "75"; echo "# Stage 3 of 3 — RLE decoding..."
    echo "100"; echo "# Done."
) | zenity --progress \
        --title="Decompressing File" \
        --text="Please wait..." \
        --percentage=0 \
        --width=400 \
        --no-cancel \
        --auto-close 2>/dev/null &
ZEN_PID=$!

bash "${SCRIPT_DIR}/smart_gzip_decompress.sh" "$INPUT_FILE" "$OUTPUT_FILE"
STATUS=$?

kill "$ZEN_PID" 2>/dev/null || true
wait "$ZEN_PID" 2>/dev/null || true

if [[ $STATUS -ne 0 ]] || [[ ! -s "$OUTPUT_FILE" ]]; then
    zenity --error --title="Decompression Failed" \
        --text="Failed to decompress:\n${INPUT_FILE}" --width=400
    exit 1
fi

ORIGINAL_SIZE="$(wc -c < "$INPUT_FILE")"
RESTORED_SIZE="$(wc -c < "$OUTPUT_FILE")"

zenity --info \
    --title="Decompression Complete" \
    --text="File decompressed successfully.\n\nCompressed Size:   ${ORIGINAL_SIZE} bytes\nRestored Size:     ${RESTORED_SIZE} bytes" \
    --width=400 2>/dev/null
