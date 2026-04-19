#!/bin/bash
#
# compress.sh
# Compression pipeline: RLE -> LZW -> gzip
#
# Usage: ./compress.sh <input_file> <output_file>
# Author: Abdullah Al Noman
# Version: 1.0


set -euo pipefail  # Exit on error, treat unset variables as errors, and fail if any command in a pipeline fails

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # Get the directory where this script is located, so we can reference other scripts in the same directory reliably regardless of the current working directory when this script is run


# Validate input file exists and is a regular file, and that required commands are available. If any validation fails, show an error message using zenity and exit with a non-zero status code to indicate failure.
validate_input() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        zenity --error --title="Error" --text="Input file not found:\n${file}" --width=400
        exit 1
    fi
}

# Run the compression pipeline: RLE -> LZW -> gzip. Show a progress dialog during execution. If any step fails, show an error message using zenity and exit with a non-zero status code. If successful, clean up temporary files and show a success message with statistics.
run_pipeline() {
    local input_file="$1"   # Input file to compress - passed as the first argument to this function
    local output_file="$2"  # Output file to write the compressed data to - passed as the second argument to this function
    local temp_rle temp_lzw # Temporary files for intermediate stages of the compression pipeline (RLE and LZW outputs)

    temp_rle="$(mktemp)"    # Create a temporary file for the RLE output. We use mktemp to create a unique temporary file securely, and we will clean it up after we're done with it. This allows us to store the intermediate output of the RLE stage without worrying about filename conflicts or security issues.
    temp_lzw="$(mktemp)"    # Create a temporary file for the LZW output. Similar to temp_rle, this will store the intermediate output of the LZW stage before we gzip it in the final step of the pipeline.

    (                       # We use a subshell to run the compression steps so that we can pipe the progress updates to zenity without affecting the main shell's execution flow. This way we can show a progress dialog while the compression is running, and we can also handle any errors that occur in the compression steps by showing an error dialog and exiting with a non-zero status code.
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


    bash "${SCRIPT_DIR}/rle_encode.sh" "$input_file" "$temp_rle"   # Run the RLE encoding stage of the pipeline, taking the input file and writing the RLE output to the temp_rle file. If this command fails, we will show an error message and exit with a non-zero status code in the main shell, but we don't need to handle that here since we're just running the command and letting any errors propagate up to the main shell.
    bash "${SCRIPT_DIR}/lzw_encode.sh" "$temp_rle"   "$temp_lzw"   # Run the LZW encoding stage of the pipeline, taking the RLE output from temp_rle and writing the LZW output to temp_lzw. Similar to the RLE stage, we just run the command and let any errors propagate up to the main shell for handling.
    gzip -9 -c "$temp_lzw" > "$output_file"   # Run the final stage of the pipeline, which is gzip compression. We use gzip with maximum compression level (-9) and write the compressed output to the specified output file. If this command fails, we will show an error message and exit with a non-zero status code in the main shell, but we don't need to handle that here since we're just running the command and letting any errors propagate up to the main shell.

    # Clean up temporary files and close the progress dialog. We kill the zenity process to close the progress dialog, and we remove the temporary files we created for the intermediate stages of the pipeline. If any of these cleanup steps fail, we will ignore the errors since we're already done with the main compression work at this point, and we just want to make sure we don't leave any temporary files around.
    kill "$zen_pid" 2>/dev/null || true
    wait "$zen_pid" 2>/dev/null || true
    rm -f "$temp_rle" "$temp_lzw"
    
    # Verify that the output file was created successfully and is not empty. If the output file was not created or is empty, we will show an error message using zenity and exit with a non-zero status code to indicate failure. If the output file was created successfully, we will show a success message with statistics in the main shell after this function returns.
    if [[ ! -f "$output_file" ]] || [[ ! -s "$output_file" ]]; then
        zenity --error --title="Error" --text="Compression failed: output file not created." --width=400
        exit 1
    fi
}

# Show a success message with statistics after compression is complete. 
#If SUPPRESS_STATS is set, skip showing the message. 
#The statistics include the original size, compressed size, and compression ratio, calculated using awk for floating-point arithmetic. 
#The message indicates that the compression was successful and what algorithm was used. 
#The dialog will be displayed with a width of 400 pixels and will not have a cancel button.
#The compression ratio is calculated using awk to perform floating-point arithmetic and format the result to one decimal place.
#If the user has chosen to suppress statistics, we will not show the message. Otherwise, we will calculate the original size, compressed size, and compression ratio, and show them in a zenity info dialog along with a message indicating that the compression was successful and what algorithm was used. The dialog will be displayed with a width of 400 pixels and will not have a cancel button.
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

#We call the validate_input function to check if the input file exists and is a regular file, and if not we show an error message and exit. 
#Then we call the run_pipeline function to execute the compression pipeline, and if any step fails we will show an error message and exit. 
#Finally, if the pipeline completes successfully, we call the show_result function to display a success message with statistics about the original size, compressed size, and compression ratio.
main() {
    local input_file="$1"
    local output_file="$2"
    validate_input "$input_file"
    run_pipeline   "$input_file" "$output_file"
    show_result    "$input_file" "$output_file"
}

main "$@"  # Call the main function with all the arguments passed to the script. The main function will handle the overall flow of the script, including validating the input, running the compression pipeline, and showing the results. By calling main with "$@", we ensure that all command-line arguments are passed through to the main function for processing.
