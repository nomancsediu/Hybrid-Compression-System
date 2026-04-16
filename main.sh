#!/bin/bash
#
# main.sh
# Entry point for the Hybrid Compression System GUI.
#
# Usage: ./main.sh
#
# Author: Abdullah Al Noman
# Version: 1.0

set +e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_menu() {
    zenity --list \
        --title="HFC Archiver" \
        --text="Select an operation" \
        --column="" \
        --width=900 --height=500 \
        --hide-header \
        "Compress File" \
        "Compress Folder" \
        "Decompress File/Archive" \
        "Encrypt File" \
        "Decrypt File" 2>/dev/null
}
handle_decompress() {
    local input_file base_name output_dir

    input_file=$(zenity --file-selection --title="Select File to Decompress" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_file" ]] && return 0

    # Check if it's a tar.gz (folder archive)
    if [[ "$input_file" == *.tar.gz ]]; then
        output_dir="$(dirname "$input_file")"
        
        zenity --progress \
            --title="Extracting Archive" \
            --text="Extracting folder..." \
            --pulsate \
            --width=400 \
            --no-cancel 2>/dev/null &
        local zen_pid=$!

        if tar -xzf "$input_file" -C "$output_dir"; then
            kill "$zen_pid" 2>/dev/null || true
            base_name="$(basename "$input_file" .tar.gz)"
            zenity --info --title="Extraction Complete" \
                --text="Archive extracted successfully to:\n${output_dir}/${base_name}" --width=400 2>/dev/null
        else
            kill "$zen_pid" 2>/dev/null || true
            zenity --error --title="Extraction Failed" \
                --text="Failed to extract archive." --width=400 2>/dev/null
        fi
        return 0
    fi

    # For other compressed files
    local dir_name name_only extension out_ext
    dir_name="$(dirname "$input_file")"
    base_name="$(basename "$input_file")"
    name_only="${base_name%.*}"
    extension="${base_name##*.}"

    # Auto-detect output extension based on input file
    if [[ "$base_name" == *.pdf.gz ]]; then
        name_only="${base_name%.pdf.gz}"
        out_ext="pdf"
    else
        out_ext="txt"
    fi

    local output_file
    output_file=$(zenity --file-selection --save \
        --title="Save Decompressed File As" \
        --filename="${dir_name}/${name_only}_restored.${out_ext}" \
        --width=700 --height=500 2>/dev/null)
    [[ -z "$output_file" ]] && return 0

    bash "${SCRIPT_DIR}/decompression/decompress.sh" "$input_file" "$output_file"
}

handle_encrypt() {
    local input_file output_file dir_name base_name name_only

    input_file=$(zenity --file-selection --title="Select File to Encrypt" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_file" ]] && return 0

    # Check file size - decline if over 1GB
    local file_size=$(wc -c < "$input_file")
    local max_size=$((1024 * 1024 * 1024))  # 1GB in bytes

    if [[ $file_size -gt $max_size ]]; then
        local size_gb=$(awk "BEGIN { printf \"%.2f\", $file_size / (1024 * 1024 * 1024) }")
        zenity --error \
            --title="File Size Exceeds Limit" \
            --text="Selected file is ${size_gb}GB, which exceeds the 1GB limit.\n\nEncryption of files this large may cause system instability.\n\nPlease select a smaller file." \
            --width=400 2>/dev/null
        return 0
    fi

    dir_name="$(dirname "$input_file")"
    name_only="$(basename "${input_file%.*}")"

    output_file=$(zenity --file-selection --save \
        --title="Save Encrypted File As" \
        --filename="${dir_name}/${name_only}.enc" \
        --width=700 --height=500 2>/dev/null)
    [[ -z "$output_file" ]] && return 0

    bash "${SCRIPT_DIR}/encryption/encrypt.sh" "$input_file" "$output_file"
}

handle_decrypt() {
    local input_file output_file dir_name base_name name_only

    input_file=$(zenity --file-selection --title="Select File to Decrypt" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_file" ]] && return 0

    # Check file size - decline if encrypted file is over 1GB
    local file_size=$(wc -c < "$input_file")
    local max_size=$((1024 * 1024 * 1024))  # 1GB in bytes

    if [[ $file_size -gt $max_size ]]; then
        local size_gb=$(awk "BEGIN { printf \"%.2f\", $file_size / (1024 * 1024 * 1024) }")
        zenity --error \
            --title="File Size Exceeds Limit" \
            --text="Selected file is ${size_gb}GB, which exceeds the 1GB limit.\n\nDecryption of files this large may cause system instability.\n\nPlease select a smaller file." \
            --width=400 2>/dev/null
        return 0
    fi

    dir_name="$(dirname "$input_file")"
    name_only="$(basename "${input_file%.*}")"

    output_file=$(zenity --file-selection --save \
        --title="Save Decrypted File As" \
        --filename="${dir_name}/${name_only}_decrypted" \
        --width=700 --height=500 2>/dev/null)
    [[ -z "$output_file" ]] && return 0

    bash "${SCRIPT_DIR}/encryption/decrypt.sh" "$input_file" "$output_file"
}

handle_compress() {
    local input_files input_file output_file dir_name base_name name_only extension input_ext out_ext
    local original_size compressed_size

    # Allow multiple file selection
    input_files=$(zenity --file-selection --multiple --title="Select File(s) to Compress" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_files" ]] && return 0

    # Convert pipe-separated string to array
    IFS='|' read -ra file_array <<< "$input_files"

    # Check total size - decline if over 1GB
    local total_size=0
    local max_size=$((1024 * 1024 * 1024))  # 1GB in bytes
    
    for input_file in "${file_array[@]}"; do
        [[ -z "$input_file" ]] && continue
        total_size=$((total_size + $(wc -c < "$input_file")))
    done

    if [[ $total_size -gt $max_size ]]; then
        local size_mb=$((total_size / (1024 * 1024)))
        zenity --error \
            --title="File Size Exceeds Limit" \
            --text="Selected file(s) total ${size_mb}MB, which exceeds the 1GB limit.\n\nCompression of files this large may cause system instability.\n\nPlease select smaller files or compress them separately." \
            --width=400 2>/dev/null
        return 0
    fi

    # Check if only one file selected
    if [[ ${#file_array[@]} -eq 1 ]]; then
        # Single file pipeline
        input_file="${file_array[0]}"
        
        dir_name="$(dirname "$input_file")"
        base_name="$(basename "$input_file")"
        name_only="${base_name%.*}"
        extension="${base_name##*.}"

        local out_ext
        [[ "${extension,,}" == "pdf" ]] && out_ext="pdf" || out_ext="gz"

        output_file=$(zenity --file-selection --save \
            --title="Save Compressed File As" \
            --filename="${dir_name}/${name_only}_compressed.${out_ext}" \
            --width=700 --height=500 2>/dev/null)
        [[ -z "$output_file" ]] && return 0

        input_ext="${input_file##*.}"
        if [[ "${input_ext,,}" == "pdf" ]]; then
            bash "${SCRIPT_DIR}/compression/compress_pdf.sh" "$input_file" "$output_file"
        else
            bash "${SCRIPT_DIR}/compression/compress.sh" "$input_file" "$output_file"
        fi
    else
        # Multiple files pipeline
        local total_original=0 total_compressed=0 file_count=0

        for input_file in "${file_array[@]}"; do
            [[ -z "$input_file" ]] && continue

            dir_name="$(dirname "$input_file")"
            base_name="$(basename "$input_file")"
            name_only="${base_name%.*}"
            extension="${base_name##*.}"

            local out_ext
            [[ "${extension,,}" == "pdf" ]] && out_ext="pdf" || out_ext="gz"

            output_file="${dir_name}/${name_only}_compressed.${out_ext}"

            input_ext="${input_file##*.}"
            if [[ "${input_ext,,}" == "pdf" ]]; then
                SUPPRESS_STATS=1 bash "${SCRIPT_DIR}/compression/compress_pdf.sh" "$input_file" "$output_file"
            else
                SUPPRESS_STATS=1 bash "${SCRIPT_DIR}/compression/compress.sh" "$input_file" "$output_file"
            fi

            # Calculate statistics
            if [[ -f "$output_file" ]]; then
                original_size=$(wc -c < "$input_file")
                compressed_size=$(wc -c < "$output_file")
                
                total_original=$((total_original + original_size))
                total_compressed=$((total_compressed + compressed_size))
                file_count=$((file_count + 1))
            fi
        done

        if [[ $file_count -gt 0 ]]; then
            local total_ratio=$(awk "BEGIN { printf \"%.1f\", (1 - ${total_compressed}/${total_original}) * 100 }")

            zenity --info \
                --title="Compression Complete" \
                --text="Files Compressed: ${file_count}\n\nTotal Original Size: ${total_original} bytes\nTotal Compressed Size: ${total_compressed} bytes\n\nCompression Ratio: ${total_ratio}%" \
                --width=400 2>/dev/null
        else
            zenity --error --title="Error" --text="No files were compressed successfully." --width=400 2>/dev/null
        fi
    fi
}

handle_compress_single() {
    # This function is no longer needed but kept for reference
    return 0
}

handle_compress_multi() {
    # This function is no longer needed but kept for reference
    return 0
}

handle_compress_folder() {
    local input_dir output_file base_name

    input_dir=$(zenity --file-selection --directory --title="Select Folder to Compress" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_dir" ]] && return 0

    # Check folder size - decline if over 1GB
    local folder_size=$(du -sb "$input_dir" | cut -f1)
    local max_size=$((1024 * 1024 * 1024))  # 1GB in bytes

    if [[ $folder_size -gt $max_size ]]; then
        local size_gb=$(awk "BEGIN { printf \"%.2f\", $folder_size / (1024 * 1024 * 1024) }")
        zenity --error \
            --title="Folder Size Exceeds Limit" \
            --text="Selected folder is ${size_gb}GB, which exceeds the 1GB limit.\n\nCompression of folders this large may cause system instability.\n\nPlease select a smaller folder or compress it separately." \
            --width=400 2>/dev/null
        return 0
    fi

    base_name="$(basename "$input_dir")"

    output_file=$(zenity --file-selection --save \
        --title="Save Compressed Folder As" \
        --filename="$(dirname "$input_dir")/${base_name}_compressed.tar.gz" \
        --width=700 --height=500 2>/dev/null)
    [[ -z "$output_file" ]] && return 0

    (
        echo "50"; echo "# Archiving and compressing folder..."
        tar -czf "$output_file" -C "$(dirname "$input_dir")" "$base_name"
        echo "100"; echo "# Done."
    ) | zenity --progress \
            --title="Compressing Folder" \
            --text="Please wait..." \
            --percentage=0 \
            --width=400 \
            --no-cancel \
            --auto-close 2>/dev/null

    local original_size compressed_size ratio
    original_size=$(du -sb "$input_dir" | cut -f1)
    compressed_size=$(wc -c < "$output_file")
    ratio=$(awk "BEGIN { printf \"%.1f\", (1 - ${compressed_size}/${original_size}) * 100 }")

    zenity --info \
        --title="Compression Complete" \
        --text="Folder compressed successfully.\n\nAlgorithm: TAR + GZIP (Level 9)\n\nOriginal Size:     ${original_size} bytes\nCompressed Size:   ${compressed_size} bytes\nCompression Ratio: ${ratio}%" \
        --width=400 2>/dev/null

    # Ask if user wants to keep the original folder
    if zenity --question \
        --title="Keep Original Folder?" \
        --text="Do you want to keep the original folder?" \
        --width=400 \
        --ok-label="Keep" \
        --cancel-label="Delete" 2>/dev/null; then
        zenity --info --title="Complete" \
            --text="Original folder retained.\nCompressed file saved to:\n${output_file}" --width=400 2>/dev/null
    else
        zenity --progress \
            --title="Deleting Original Folder" \
            --text="Removing original folder..." \
            --pulsate \
            --width=400 \
            --no-cancel 2>/dev/null &
        local zen_pid=$!

        rm -rf "$input_dir"
        
        kill "$zen_pid" 2>/dev/null || true

        zenity --info --title="Complete" \
            --text="Original folder deleted.\nCompressed file saved to:\n${output_file}" --width=400 2>/dev/null
    fi
}

main() {
    while true; do
        local choice
        choice=$(show_menu)
        [[ -z "$choice" ]] && exit 0

        case "$choice" in
            "Compress File")         handle_compress         ;;
            "Compress Folder")       handle_compress_folder  ;;
            "Decompress File/Archive") handle_decompress     ;;
            "Encrypt File")          handle_encrypt          ;;
            "Decrypt File")          handle_decrypt          ;;
        esac
    done
}

main
