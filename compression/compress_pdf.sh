#!/bin/bash
#
# compress_pdf.sh
# PDF-specific compression using Ghostscript.
#
# Algorithms used:
#   - DCT (Discrete Cosine Transform) for image compression (lossy)
#   - Flate/LZW for text and fonts (lossless)
#
# Quality levels:
#   screen   = 72 dpi  (smallest size, lowest quality)
#   ebook    = 150 dpi (good balance)
#   printer  = 300 dpi (high quality)
#
# Usage: ./compress_pdf.sh <input_file> <output_file>
#
# Author: Abdullah Al Noman
# Version: 1.0

set -euo pipefail     # Exit on error, treat unset variables as errors, and fail if any command in a pipeline fails


# Function to validate input file and required tools.
# We check if the input file exists and is a regular file. If not, we show an error message using zenity and exit with a non-zero status code to indicate failure. 
# We also check if the Ghostscript command (gs) is available on the system, and if not, we show an error message with instructions on how to install it and exit with a non-zero status code.
# This ensures that we have the necessary input and tools to perform the PDF compression before we proceed with the rest of the script.
validate_input() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        zenity --error --title="Error" --text="File not found:\n${file}" --width=400
        exit 1
    fi
    if ! command -v gs &>/dev/null; then
        zenity --error --title="Error" \
            --text="Ghostscript (gs) is not installed.\nInstall it with:\n\n  sudo apt install ghostscript" \
            --width=400
        exit 1
    fi
}


# Function to prompt the user to select a compression quality level using zenity.
select_quality() {
    zenity --list \
        --title="PDF Compression Quality" \
        --text="Select compression level:" \
        --column="Level" --column="Description" \
        "screen"   "Smallest size - 72 DPI (lowest quality)" \
        "ebook"    "Balanced - 150 DPI (recommended)" \
        "printer"  "High quality - 300 DPI" \
        --hide-column=1 --print-column=1 \
        --width=500 --height=260 \
        --modal 2>/dev/null
}


# Function to perform PDF compression using Ghostscript. We run the gs command with the appropriate options to apply DCT compression to images and Flate/LZW compression to text and fonts. 
# We also show a progress dialog using zenity while the compression is running, and we handle any errors that occur during the compression by showing an error message with the details from Ghostscript's output
# If the compression is successful, we clean up any temporary files and return from the function.

compress() {
    local input_file="$1"
    local output_file="$2"
    local quality="$3"
    local gs_log
    gs_log="$(mktemp)"

    (
        echo "10"; echo "# Analyzing PDF structure..."
        sleep 0.3
        echo "30"; echo "# Applying DCT compression to images..."
    ) | zenity --progress \
            --title="Compressing PDF" \
            --text="Please wait..." \
            --percentage=0 \
            --width=400 \
            --no-cancel 2>/dev/null &
    local zen_pid=$!

    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=/"$quality" \
       -dNOPAUSE \
       -dQUIET \
       -dBATCH \
       -sOutputFile="$output_file" \
       "$input_file" 2>"$gs_log"
    local gs_exit=$?

    kill "$zen_pid" 2>/dev/null || true
    wait "$zen_pid" 2>/dev/null || true

    if [[ $gs_exit -ne 0 ]] || [[ ! -f "$output_file" ]] || [[ ! -s "$output_file" ]]; then
        local err_msg
        err_msg="$(cat "$gs_log")"
        rm -f "$gs_log"
        zenity --error --title="Compression Failed" \
            --text="Ghostscript failed to compress the PDF.\n\n${err_msg}" \
            --width=400
        exit 1
    fi

    rm -f "$gs_log"
}



# Function to show a success message with statistics about the original and compressed PDF. We calculate the original size, compressed size, and compression ratio, and then display this information in a zenity info dialog. 
# If the user has chosen to suppress statistics (by setting the SUPPRESS_STATS environment variable), we skip showing the message. Otherwise, we show the statistics along with a message indicating that the compression was successful and what algorithm was used. The dialog will be displayed with a width of 400 pixels and will not have a cancel button.
# The compression ratio is calculated using awk to perform floating-point arithmetic
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
        --title="PDF Compression Complete" \
        --text="PDF compressed successfully.\n\nAlgorithm: DCT (Discrete Cosine Transform)\n\nOriginal Size:     ${original_size} bytes\nCompressed Size:   ${compressed_size} bytes\nCompression Ratio: ${ratio}%" \
        --width=400 2>/dev/null
}




# Main function to validate input, run compression, and show results. 
main() {
    local input_file="$1"
    local output_file="$2"
    local quality

    validate_input "$input_file"

    quality="$(select_quality)"
    [[ -z "$quality" ]] && exit 0

    compress    "$input_file" "$output_file" "$quality"
    show_result "$input_file" "$output_file"
}

main "$@"
