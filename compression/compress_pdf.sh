#!/bin/bash
#
# compress_pdf.sh
# PDF-specific compression using Ghostscript.
#
# Algorithms used:
#   - DCT (Discrete Cosine Transform) for image compression (lossy)
#   - Flate/LZW for text and fonts (lossless)
#
# Quality levels:
#   screen   = 72 dpi  (smallest size, lowest quality)
#   ebook    = 150 dpi (good balance)
#   printer  = 300 dpi (high quality)
#
# Usage: ./compress_pdf.sh <input_file> <output_file>
#
# Author: Abdullah Al Noman
# Version: 1.0

set -euo pipefail

validate_input() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        zenity --error --title="Error" --text="File not found:\n${file}" --width=400
        exit 1
    fi
    if ! command -v gs &>/dev/null; then
        zenity --error --title="Error" \
            --text="Ghostscript (gs) is not installed.\nInstall it with:\n\n  sudo apt install ghostscript" \
            --width=400
        exit 1
    fi
}

select_quality() {
    zenity --list \
        --title="PDF Compression Quality" \
        --text="Select compression level:" \
        --column="Level" --column="Description" \
        "screen"   "Smallest size - 72 DPI (lowest quality)" \
        "ebook"    "Balanced - 150 DPI (recommended)" \
        "printer"  "High quality - 300 DPI" \
        --hide-column=1 --print-column=1 \
        --width=500 --height=260 \
        --modal 2>/dev/null
}

compress() {
    local input_file="$1"
    local output_file="$2"
    local quality="$3"
    local gs_log
    gs_log="$(mktemp)"

    (
        echo "10"; echo "# Analyzing PDF structure..."
        sleep 0.3
        echo "30"; echo "# Applying DCT compression to images..."
    ) | zenity --progress \
            --title="Compressing PDF" \
            --text="Please wait..." \
            --percentage=0 \
            --width=400 \
            --no-cancel 2>/dev/null &
    local zen_pid=$!

    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=/"$quality" \
       -dNOPAUSE \
       -dQUIET \
       -dBATCH \
       -sOutputFile="$output_file" \
       "$input_file" 2>"$gs_log"
    local gs_exit=$?

    kill "$zen_pid" 2>/dev/null || true
    wait "$zen_pid" 2>/dev/null || true

    if [[ $gs_exit -ne 0 ]] || [[ ! -f "$output_file" ]] || [[ ! -s "$output_file" ]]; then
        local err_msg
        err_msg="$(cat "$gs_log")"
        rm -f "$gs_log"
        zenity --error --title="Compression Failed" \
            --text="Ghostscript failed to compress the PDF.\n\n${err_msg}" \
            --width=400
        exit 1
    fi

    rm -f "$gs_log"
}

show_result() {
    local input_file="$1"
    local output_file="$2"
    local original_size compressed_size ratio

    # Skip showing result if SUPPRESS_STATS is set
    [[ -n "${SUPPRESS_STATS:-}" ]] && return 0

    original_size="$(wc -c < "$input_file")"
    compressed_size="$(wc -c < "$output_file")"
    ratio="$(awk "BEGIN { printf \"%.1f\", (1 - ${compressed_size}/${original_size}) * 100 }")"

    zenity --info \
        --title="PDF Compression Complete" \
        --text="PDF compressed successfully.\n\nAlgorithm: DCT (Discrete Cosine Transform)\n\nOriginal Size:     ${original_size} bytes\nCompressed Size:   ${compressed_size} bytes\nCompression Ratio: ${ratio}%" \
        --width=400 2>/dev/null
}

main() {
    local input_file="$1"
    local output_file="$2"
    local quality

    validate_input "$input_file"

    quality="$(select_quality)"
    [[ -z "$quality" ]] && exit 0

    compress    "$input_file" "$output_file" "$quality"
    show_result "$input_file" "$output_file"
}

main "$@"
