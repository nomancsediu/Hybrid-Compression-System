#!/bin/bash
#
# lzw_encode.sh
# LZW compression: reads input, outputs one integer code per line.
# Dictionary is rebuilt identically during decode — no need to store it.
#
# Usage: ./lzw_encode.sh <input_file> <output_file>
# Author: Abdullah Al Noman
# Version: 1.0

set -euo pipefail  # Exit on error, treat unset variables as errors, and fail if any command in a pipeline fails

# Validate that the input file exists and is a regular file
[[ ! -f "$1" ]] && { echo "Error: file not found: $1" >&2; exit 1; }


awk '
BEGIN {
    # initialise dictionary with all single bytes 0-255
    for (i = 0; i < 256; i++) {
        dict[sprintf("%c", i)] = i   # Initialize the dictionary with single-byte characters (0-255) as keys and their corresponding integer codes as values. We use sprintf("%c", i) to convert the integer i to its corresponding ASCII character, which becomes the key in the dictionary. The value for each key is simply the integer code i, which allows us to look up the code for any single-byte character directly from the dictionary.
    }
    next_code = 256  # Next available code after the initial single-byte characters
    w = ""           
    ORS = "\n"
}

{
    n = length($0)
    for (i = 1; i <= n; i++) {
        c  = substr($0, i, 1)
        wc = w c
        if (wc in dict) {
            w = wc
        } else {
            print dict[w]
            dict[wc] = next_code++
            w = c
        }
    }
    # newline character between lines
    wc = w "\n"
    if (wc in dict) {
        w = wc
    } else {
        print dict[w]
        dict[wc] = next_code++
        w = "\n"
    }
}
END {
    if (w != "") print dict[w]
}
' "$1" > "$2"
