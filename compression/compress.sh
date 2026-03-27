#!/bin/bash
#
# compress.sh
# Smart compression: detects file type and applies appropriate algorithm
# - Text files: RLE -> LZW -> gzip
# - Already-compressed/binary: gzip only
#
# Usage: ./compress.sh <input_file> <output_file>

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

validate_input() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        zenity --error --title="Error" --text="Input file not found:\n${file}" --width=400
        exit 1
    fi
}

is_compressible() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"
    
    local compressed_exts="zip docx xlsx pptx jpg jpeg png gif mp4 mp3 rar gz bz2 7z webp heic"
    for fmt in $compressed_exts; do
        [[ "$ext" == "$fmt" ]] && return 1
    done
    return 0
}

run_pipeline() {
    local input_file="$1"
    local output_file="$2"
    local temp_rle temp_lzw

    temp_rle="$(mktemp)"
    temp_lzw="$(mktemp)"

    (
        echo "10"; echo "# Stage 1 of 3 - Run-Length Encoding..."
        sleep 0.3
        echo "40"; echo "# Stage 2 of 3 - LZW Encoding..."
        sleep 0.3
        echo "80"; echo "# Stage 3 of 3 - GZIP Compression..."
        sleep 0.3
        echo "100"; echo "# Done."
    ) | zenity --progress \
            --title="Compressing File" \
            --text="Please wait..." \
            --percentage=0 \
            --width=400 \
            --no-cancel \
            --auto-close 2>/dev/null &
    local zen_pid=$!

    bash "${SCRIPT_DIR}/rle_encode.sh" "$input_file" "$temp_rle"
    bash "${SCRIPT_DIR}/lzw_encode.sh" "$temp_rle"   "$temp_lzw"
    gzip -9 -c "$temp_lzw" > "$output_file"

    kill "$zen_pid" 2>/dev/null || true
    wait "$zen_pid" 2>/dev/null || true
    rm -f "$temp_rle" "$temp_lzw"

    if [[ ! -f "$output_file" ]] || [[ ! -s "$output_file" ]]; then
        zenity --error --title="Error" --text="Compression failed: output file not created." --width=400
        exit 1
    fi
}

run_gzip_only() {
    local input_file="$1"
    local output_file="$2"

    (
        echo "50"; echo "# Applying GZIP compression..."
        sleep 0.3
        echo "100"; echo "# Done."
    ) | zenity --progress \
            --title="Compressing File" \
            --text="Please wait..." \
            --percentage=0 \
            --width=400 \
            --no-cancel \
            --auto-close 2>/dev/null &
    local zen_pid=$!

    gzip -9 -c "$input_file" > "$output_file"

    kill "$zen_pid" 2>/dev/null || true
    wait "$zen_pid" 2>/dev/null || true

    if [[ ! -f "$output_file" ]] || [[ ! -s "$output_file" ]]; then
        zenity --error --title="Error" --text="Compression failed: output file not created." --width=400
        exit 1
    fi
}

show_result() {
    local input_file="$1"
    local output_file="$2"
    local algorithm="$3"
    local original_size compressed_size ratio

    original_size="$(wc -c < "$input_file")"
    compressed_size="$(wc -c < "$output_file")"
    ratio="$(awk "BEGIN { printf \"%.1f\", (1 - ${compressed_size}/${original_size}) * 100 }")"

    zenity --info \
        --title="Compression Complete" \
        --text="File compressed successfully.\n\nAlgorithm: ${algorithm}\n\nOriginal Size:     ${original_size} bytes\nCompressed Size:   ${compressed_size} bytes\nCompression Ratio: ${ratio}%" \
        --width=400 2>/dev/null
}

main() {
    local input_file="$1"
    local output_file="$2"
    validate_input "$input_file"
    
    if is_compressible "$input_file"; then
        run_pipeline "$input_file" "$output_file"
        show_result  "$input_file" "$output_file" "RLE + LZW + GZIP"
    else
        run_gzip_only "$input_file" "$output_file"
        show_result   "$input_file" "$output_file" "GZIP Only (Pre-compressed format detected)"
    fi
}

main "$@"
