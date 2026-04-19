#!/bin/bash
#
# rle_encode.sh
# Applies Run-Length Encoding (RLE) to a text file.
# Consecutive characters repeated 3 or more times are replaced
# with their count followed by the character (e.g. AAAAA -> 5A).
# Sequences shorter than 3 are written as-is to avoid size inflation.
#
# Usage: ./rle_encode.sh <input_file> <output_file>
#
# Author: Abdullah Al Noman
# Version: 1.0

set -euo pipefail

# Validate that the input file exists and is a regular file. 
validate_input() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "Error: input file not found: ${file}" >&2
        exit 1
    fi
}


#RLE encoding function. Reads the input file, applies RLE encoding, and writes the output to the specified output file.

encode() {
    local input_file="$1" 
    local output_file="$2" 

    awk '                  
    BEGIN { ORS = "" }     #
    {
        n = length($0)
        for (i = 1; i <= n; i++) {
            c = substr($0, i, 1)
            if (c == prev) {
                count++
            } else {
                if (prev != "") {
                    if (count >= 3)
                        printf "%d%s", count, prev
                    else
                        for (j = 0; j < count; j++) printf "%s", prev
                }
                prev  = c
                count = 1
            }
        }
        if (prev != "") {
            if (count >= 3)
                printf "%d%s", count, prev
            else
                for (j = 0; j < count; j++) printf "%s", prev
        }
        printf "\n"
        prev  = ""
        count = 0
    }
    ' "$input_file" > "$output_file"
}


# Main function to validate input and run the encoding.
main() {
    local input_file="$1"
    local output_file="$2"

    validate_input "$input_file"
    encode         "$input_file" "$output_file"
}

main "$@"