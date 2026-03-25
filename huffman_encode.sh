#!/bin/bash
#
# huffman_encode.sh
# Applies Huffman-based encoding by compressing the RLE output
# into a standard ZIP archive using the system zip utility.
#
# Usage: ./huffman_encode.sh <input_file> <output_file>
#
# Author: Abdullah Al Noman
# Version: 1.0

set -euo pipefail

# ---------------------------------------------------------------------------
# validate_input <file>
# ---------------------------------------------------------------------------
validate_input() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "Error: input file not found: ${file}" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# encode <input_file> <output_file>
#   Creates a ZIP archive from the input file.
#   The -j flag strips directory paths, storing only the file itself.
# ---------------------------------------------------------------------------
encode() {
    local input_file="$1"
    local output_file="$2"

    zip -q -j "$output_file" "$input_file"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
    local input_file="$1"
    local output_file="$2"

    validate_input "$input_file"
    encode         "$input_file" "$output_file"
}

main "$@"
