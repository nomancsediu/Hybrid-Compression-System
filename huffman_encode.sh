#!/bin/bash
# Huffman Encoding: Using zip for compression

input_file="$1"
output_file="$2"

if [ ! -f "$input_file" ]; then
    echo "Error: Input file not found"
    exit 1
fi

# Create zip archive
zip -q -j "$output_file" "$input_file"
