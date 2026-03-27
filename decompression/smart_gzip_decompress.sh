#!/bin/bash
# Smart GZIP decompression script
# Handles both RLE+LZW+GZIP and plain GZIP compressed files
# Usage: ./smart_gzip_decompress.sh <input_file> <output_file>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

temp_gunzip="$(mktemp)"
trap "rm -f '$temp_gunzip'" EXIT

# Step 1: Decompress GZIP
gunzip -c "$INPUT_FILE" > "$temp_gunzip"
if [[ $? -ne 0 ]]; then
    echo "Error: GZIP decompression failed" >&2
    exit 1
fi

# Step 2: Detect if this is LZW encoded data
# LZW output has one integer code per line
# Check if ALL lines are purely numeric
is_lzw_encoded() {
    local file="$1"
    # Read first 5 lines and check if they're all numeric
    local all_numeric=true
    local line_count=0
    while IFS= read -r line && [[ $line_count -lt 5 ]]; do
        ((line_count++))
        # Skip empty lines
        [[ -z "$line" ]] && continue
        # If line contains any non-digit, it's not LZW encoded
        if ! [[ "$line" =~ ^[0-9]+$ ]]; then
            all_numeric=false
            break
        fi
    done < "$file"
    
    [[ "$all_numeric" == "true" ]] && return 0 || return 1
}

if is_lzw_encoded "$temp_gunzip"; then
    # This is LZW encoded data, needs full pipeline reversal
    temp_lzw_decoded="$(mktemp)"
    trap "rm -f '$temp_gunzip' '$temp_lzw_decoded'" EXIT
    
    # Step 2a: Decode LZW
    bash "${SCRIPT_DIR}/lzw_decode.sh" "$temp_gunzip" "$temp_lzw_decoded"
    if [[ $? -ne 0 ]]; then
        echo "Error: LZW decoding failed" >&2
        exit 1
    fi

    # Step 3: Decode RLE
    bash "${SCRIPT_DIR}/rle_decode.sh" "$temp_lzw_decoded" "$OUTPUT_FILE"
    if [[ $? -ne 0 ]]; then
        echo "Error: RLE decoding failed" >&2
        exit 1
    fi
else
    # This is plain GZIP, no LZW/RLE to decode
    cp "$temp_gunzip" "$OUTPUT_FILE"
fi

echo "Smart GZIP decompression complete: $OUTPUT_FILE"

