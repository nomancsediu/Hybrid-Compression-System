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

# ---------------------------------------------------------------------------
# show_menu
#   Displays the main menu and returns the user's choice.
# ---------------------------------------------------------------------------
show_menu() {
    zenity --list \
        --title="Hybrid Compression System" \
        --text="Select an operation" \
        --column="Operation" \
        --width=500 --height=250 \
        --modal \
        "Compress File" \
        "Exit" 2>/dev/null
}

# ---------------------------------------------------------------------------
# select_input_file
#   Opens a file chooser and returns the selected file path.
# ---------------------------------------------------------------------------
select_input_file() {
    zenity --file-selection \
        --title="Select File to Compress" \
        --width=700 --height=500 2>/dev/null
}

# ---------------------------------------------------------------------------
# select_output_file <default_path>
#   Opens a save dialog with a suggested filename and returns the chosen path.
# ---------------------------------------------------------------------------
select_output_file() {
    local default_path="$1"

    zenity --file-selection \
        --save \
        --title="Save Compressed File As" \
        --filename="$default_path" \
        --width=700 --height=500 2>/dev/null
}

# ---------------------------------------------------------------------------
# build_output_path <input_file>
#   Derives the default output .zip path from the input filename.
# ---------------------------------------------------------------------------
build_output_path() {
    local input_file="$1"
    local dir_name base_name name_only

    dir_name="$(dirname "$input_file")"
    base_name="$(basename "$input_file")"
    name_only="${base_name%.*}"

    echo "${dir_name}/${name_only}.zip"
}

# ---------------------------------------------------------------------------
# handle_compress
#   Orchestrates file selection and delegates to compress.sh.
# ---------------------------------------------------------------------------
handle_compress() {
    local input_file output_file default_output

    input_file="$(select_input_file)"
    [[ -z "$input_file" ]] && return 0

    default_output="$(build_output_path "$input_file")"

    output_file="$(select_output_file "$default_output")"
    [[ -z "$output_file" ]] && return 0

    bash "${SCRIPT_DIR}/compress.sh" "$input_file" "$output_file"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
    while true; do
        local choice
        choice="$(show_menu)" || true

        case "$choice" in
            "Compress File") handle_compress ;;
            "Exit" | "")     exit 0 ;;
        esac
    done
}

main
