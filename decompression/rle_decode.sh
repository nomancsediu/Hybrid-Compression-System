#!/bin/bash
# RLE decompression script
# Usage: ./rle_decode.sh <input_file> <output_file>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# RLE decompression logic
awk '
BEGIN { ORS = "" }
{
    line = $0
    n = length(line)
    i = 1
    while (i <= n) {
        c = substr(line, i, 1)
        if (c ~ /[0-9]/) {
            # Parse count (must convert to number for proper loop iteration)
            count = 0
            while (i <= n && substr(line, i, 1) ~ /[0-9]/) {
                count = count * 10 + substr(line, i, 1)
                i++
            }
            char = substr(line, i, 1)
            for (j = 0; j < count; j++) printf "%s", char
            i++
        } else {
            printf "%s", c
            i++
        }
    }
    printf "\n"
}
' "$INPUT_FILE" > "$OUTPUT_FILE"
