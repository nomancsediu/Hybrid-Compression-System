#!/bin/bash
# PDF decompression script (placeholder)
# Usage: ./decompress_pdf.sh <input_file> <output_file>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

# PDF decompression using Ghostscript
if ! command -v gs &>/dev/null; then
    echo "Ghostscript (gs) is not installed. Install it with: sudo apt install ghostscript" >&2
    exit 1
fi

# Attempt to decompress by converting to high quality
gs -sDEVICE=pdfwrite \
   -dCompatibilityLevel=1.4 \
   -dPDFSETTINGS=/printer \
   -dNOPAUSE \
   -dQUIET \
   -dBATCH \
   -sOutputFile="$OUTPUT_FILE" \
   "$INPUT_FILE"

if [[ $? -ne 0 ]] || [[ ! -f "$OUTPUT_FILE" ]] || [[ ! -s "$OUTPUT_FILE" ]]; then
    echo "Ghostscript failed to decompress the PDF." >&2
    exit 1
fi

echo "PDF decompression complete: $OUTPUT_FILE"
