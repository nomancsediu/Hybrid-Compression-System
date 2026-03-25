#!/bin/bash
# RLE Encoding: Text-based simple format

input_file="$1"
output_file="$2"

if [ ! -f "$input_file" ]; then
    echo "Error: Input file not found"
    exit 1
fi

# Simple character-based RLE for text
awk 'BEGIN{ORS=""}
{
    for(i=1; i<=length($0); i++) {
        c = substr($0, i, 1)
        if(c == prev) {
            count++
        } else {
            if(prev != "") {
                if(count >= 3) printf "%d%s", count, prev
                else for(j=0; j<count; j++) printf "%s", prev
            }
            prev = c
            count = 1
        }
    }
    if(prev != "") {
        if(count >= 3) printf "%d%s", count, prev
        else for(j=0; j<count; j++) printf "%s", prev
    }
    printf "\n"
    prev = ""
    count = 0
}' "$input_file" > "$output_file"
