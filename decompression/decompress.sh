#!/bin/bash
# Main decompression script to orchestrate decompression methods
# Auto-detects compression method based on file extension

# Usage: ./decompress.sh <input_file> <output_file>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# Auto-detect method based on file extension
if [[ "$INPUT_FILE" == *.pdf.gz ]]; then
    # PDF compressed file
    METHOD="pdf"
elif [[ "$INPUT_FILE" == *.gz ]]; then
    # Standard gzip compressed file (could be RLE+LZW+GZIP pipeline)
    METHOD="gzip"
else
    echo "Error: Unsupported file format. Expected .gz or .pdf.gz files"
    exit 1
fi

case "$METHOD" in
    pdf)
        bash "$(dirname "$0")/smart_gzip_decompress.sh" "$INPUT_FILE" "$OUTPUT_FILE"
        ;;
    gzip)
        bash "$(dirname "$0")/smart_gzip_decompress.sh" "$INPUT_FILE" "$OUTPUT_FILE"
        ;;
    *)
        echo "Unknown method: $METHOD"
        exit 1
        ;;
esac

