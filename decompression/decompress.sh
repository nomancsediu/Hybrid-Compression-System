#!/bin/bash
# Main decompression script to orchestrate decompression methods

# Usage: ./decompress.sh <input_file> <output_file> <method>
# method: lzw | rle | pdf | gzip

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <input_file> <output_file> <method>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
METHOD="$3"

case "$METHOD" in
    lzw)
        bash "$(dirname "$0")/lzw_decode.sh" "$INPUT_FILE" "$OUTPUT_FILE"
        ;;
    rle)
        bash "$(dirname "$0")/rle_decode.sh" "$INPUT_FILE" "$OUTPUT_FILE"
        ;;
    pdf)
        bash "$(dirname "$0")/decompress_pdf.sh" "$INPUT_FILE" "$OUTPUT_FILE"
        ;;
    gzip)
        bash "$(dirname "$0")/smart_gzip_decompress.sh" "$INPUT_FILE" "$OUTPUT_FILE"
        ;;
    *)
        echo "Unknown method: $METHOD"
        exit 1
        ;;
esac
