#!/bin/bash
# LZW decompression script
# Usage: ./lzw_decode.sh <input_file> <output_file>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# LZW decompression logic
awk '
BEGIN {
    for (i = 0; i < 256; i++) {
        dict[i] = sprintf("%c", i)
    }
    next_code = 256
    prev = ""
}
{
    code = $1
    if (code in dict) {
        entry = dict[code]
    } else if (code == next_code) {
        entry = prev prev_substr
    } else {
        print "Decoding error: unknown code " code > "/dev/stderr"
        exit 1
    }
    printf "%s", entry
    if (prev != "") {
        prev_substr = substr(entry, 1, 1)
        dict[next_code++] = prev prev_substr
    }
    prev = entry
}
' "$INPUT_FILE" > "$OUTPUT_FILE"
