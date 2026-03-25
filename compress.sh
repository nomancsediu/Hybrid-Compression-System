#!/bin/bash
#
# compress.sh
# Compression pipeline: RLE encoding followed by Huffman (zip) encoding.
#
# Usage: ./compress.sh <input_file> <output_file>
#
# Author: Abdullah Al Noman
# Version: 1.0

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# validate_input <file>
#   Exits with an error dialog if the given file does not exist.
# ---------------------------------------------------------------------------
validate_input() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        zenity --error \
            --title="Error" \
            --text="Input file not found:\n${file}" \
            --width=400
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# run_pipeline <input_file> <output_file>
#   Executes the two-stage compression pipeline with a progress dialog.
# ---------------------------------------------------------------------------
run_pipeline() {
    local input_file="$1"
    local output_file="$2"
    local temp_rle

    temp_rle="$(mktemp)"

    (
        echo "10"; echo "# Stage 1 of 2 — Run-Length Encoding..."
        bash "${SCRIPT_DIR}/rle_encode.sh" "$input_file" "$temp_rle"

        echo "60"; echo "# Stage 2 of 2 — Huffman Encoding..."
        bash "${SCRIPT_DIR}/huffman_encode.sh" "$temp_rle" "$output_file"

        echo "100"; echo "# Compression complete."
    ) | zenity --progress \
            --title="Compressing File" \
            --text="Please wait..." \
            --percentage=0 \
            --width=400 \
            --auto-close 2>/dev/null

    rm -f "$temp_rle"
}

# ---------------------------------------------------------------------------
# show_result <input_file> <output_file>
#   Displays a summary dialog with file sizes and compression ratio.
# ---------------------------------------------------------------------------
show_result() {
    local input_file="$1"
    local output_file="$2"
    local original_size compressed_size ratio

    original_size="$(wc -c < "$input_file")"
    compressed_size="$(wc -c < "$output_file")"
    ratio="$(awk "BEGIN { printf \"%.1f\", (1 - ${compressed_size}/${original_size}) * 100 }")"

    zenity --info \
        --title="Compression Complete" \
        --text="File compressed successfully.\n\nOriginal Size:    ${original_size} bytes\nCompressed Size:  ${compressed_size} bytes\nCompression Ratio: ${ratio}%" \
        --width=400 2>/dev/null
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
    local input_file="$1"
    local output_file="$2"

    validate_input "$input_file"
    run_pipeline   "$input_file" "$output_file"
    show_result    "$input_file" "$output_file"
}

main "$@"
