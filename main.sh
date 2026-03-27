#!/bin/bash
#
# main.sh
# Entry point for the Hybrid Compression System GUI.
#
# Usage: ./main.sh
#
# Author: Abdullah Al Noman
# Version: 1.0

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_menu() {
    zenity --list \
        --title="Hybrid Compression System" \
        --text="Select an operation" \
        --column="Operation" \
        --width=500 --height=320 \
        --modal \
        "Compress File" \
        "Decompress File" \
        "Exit" 2>/dev/null
}
handle_decompress() {
    local input_file output_file dir_name base_name name_only extension out_ext

    input_file=$(zenity --file-selection --title="Select File to Decompress" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_file" ]] && return 0

    dir_name="$(dirname "$input_file")"
    base_name="$(basename "$input_file")"
    name_only="${base_name%.*}"
    extension="${base_name##*.}"

    # Auto-detect output extension based on input file
    if [[ "$base_name" == *.pdf.gz ]]; then
        # PDF compressed file
        name_only="${base_name%.pdf.gz}"
        out_ext="pdf"
    else
        # Regular compressed file
        out_ext="txt"
    fi

    output_file=$(zenity --file-selection --save \
        --title="Save Decompressed File As" \
        --filename="${dir_name}/${name_only}_restored.${out_ext}" \
        --width=700 --height=500 2>/dev/null)
    [[ -z "$output_file" ]] && return 0

    bash "${SCRIPT_DIR}/decompression/decompress.sh" "$input_file" "$output_file"
}

handle_compress() {
    local input_file output_file dir_name base_name name_only extension

    input_file=$(zenity --file-selection --title="Select File to Compress" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_file" ]] && return 0

    dir_name="$(dirname "$input_file")"
    base_name="$(basename "$input_file")"
    name_only="${base_name%.*}"
    extension="${base_name##*.}"

    local out_ext
    [[ "${extension,,}" == "pdf" ]] && out_ext="pdf" || out_ext="gz"

    output_file=$(zenity --file-selection --save \
        --title="Save Compressed File As" \
        --filename="${dir_name}/${name_only}_compressed.${out_ext}" \
        --width=700 --height=500 2>/dev/null)
    [[ -z "$output_file" ]] && return 0

    local input_ext
    input_ext="${input_file##*.}"
    if [[ "${input_ext,,}" == "pdf" ]]; then
        bash "${SCRIPT_DIR}/compression/compress_pdf.sh" "$input_file" "$output_file"
    else
        bash "${SCRIPT_DIR}/compression/compress.sh" "$input_file" "$output_file"
    fi
}

main() {
    while true; do
        local choice
        choice="$(show_menu)" || true

        case "$choice" in
            "Compress File") handle_compress ;;
            "Decompress File") handle_decompress ;;
            "Exit" | "")      exit 0           ;;
        esac
    done
}

main
