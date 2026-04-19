#!/bin/bash
#
# compress.sh
# Compression pipeline: RLE -> LZW -> gzip
#
# Usage: ./compress.sh <input_file> <output_file>
# Author: Abdullah Al Noman
# Version: 1.0


set -euo pipefail  # Exit on error

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # Get the directory where this script is located.


# Validate input file exists and is a regular file, and that required commands are available
validate_input() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        zenity --error --title="Error" --text="Input file not found:\n${file}" --width=400
        exit 1
    fi
}

# Run the compression pipeline: RLE -> LZW -> gzip. Show a progress dialog during execution
run_pipeline() {
    local input_file="$1"   # Input file to compress - passed as the first argument to this function
    local output_file="$2"  # Output file to write the compressed data to - passed as the second argument to this function
    local temp_rle temp_lzw # Temporary files for intermediate stages of the compression pipeline (RLE and LZW outputs)

    temp_rle="$(mktemp)"    # Create a temporary file for the RLE output.
    temp_lzw="$(mktemp)"    # Create a temporary file for the LZW output.

     # We use a subshell to run the compression steps so that we can pipe the progress updates to zenity without affecting the main shell's execution flow. 

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




    bash "${SCRIPT_DIR}/rle_encode.sh" "$input_file" "$temp_rle"   # Run the RLE encoding stage of the pipeline
    bash "${SCRIPT_DIR}/lzw_encode.sh" "$temp_rle"   "$temp_lzw"   # Run the LZW encoding stage of the pipeline
    gzip -9 -c "$temp_lzw" > "$output_file"   # Run the final stage of the pipeline, which is gzip compression



    # Clean up temporary files and close the progress dialog. 
    kill "$zen_pid" 2>/dev/null || true
    wait "$zen_pid" 2>/dev/null || true
    rm -f "$temp_rle" "$temp_lzw"
    


    # Verify that the output file was created successfully and is not empty. 
    if [[ ! -f "$output_file" ]] || [[ ! -s "$output_file" ]]; then
        zenity --error --title="Error" --text="Compression failed: output file not created." --width=400
        exit 1
    fi
}

#Show a success message with statistics after compression is complete.
show_result() {
    local input_file="$1"
    local output_file="$2"
    local original_size compressed_size ratio

    # Skip showing result if SUPPRESS_STATS is set
    [[ -n "${SUPPRESS_STATS:-}" ]] && return 0

    original_size="$(wc -c < "$input_file")"
    compressed_size="$(wc -c < "$output_file")"
    ratio="$(awk "BEGIN { printf \"%.1f\", (1 - ${compressed_size}/${original_size}) * 100 }")"

    zenity --info \
        --title="Compression Complete" \
        --text="File compressed successfully.\n\nAlgorithm: RLE + LZW + GZIP\n\nOriginal Size:     ${original_size} bytes\nCompressed Size:   ${compressed_size} bytes\nCompression Ratio: ${ratio}%" \
        --width=400 2>/dev/null
}

main() {
    local input_file="$1"
    local output_file="$2"
    validate_input "$input_file"
    run_pipeline   "$input_file" "$output_file"
    show_result    "$input_file" "$output_file"
}

main "$@"  # Call the main function with all the arguments passed to the script.
