#!/bin/bash   #Shebang line to specify the interpreter to execute the script 
#----------------------------------------------------------------------------------------------------|
# main.sh - Entry point for the Hybrid Compression System GUI.                                       |
# Author: Abdullah Al Noman, Supan Roy, Md. Ibrahim Hossain Joy, Dilruba Jeba, Md Awal Hossain Munna |
# Version: 2.1                                                                                       |
#----------------------------------------------------------------------------------------------------|


# Allow commands to fail without exiting immediately
set +e 

# Get the directory of the current script
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 


# Function to display the main menu using zenity and return the user's choice
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

#---------------------------------------------|
#Contributed by Abdullah Al Noman (232-15-797)|
#---------------------------------------------|
handle_compress() {
    local input_files input_file output_file dir_name base_name name_only extension input_ext out_ext
    local original_size compressed_size

    # Allow multiple file selection
    input_files=$(zenity --file-selection --multiple --title="Select File(s) to Compress" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_files" ]] && return 0

    # Split the input string into an array using '|' as the delimiter
    IFS='|' read -ra file_array <<< "$input_files"   


    local total_size=0
    # 1GB in bytes - Check total size of selected files - decline if over 1GB
    local max_size=$((1024 * 1024 * 1024))  
    

    # Accumulate the total size of all selected files and call the wc command to get the size of each file in bytes and add it to the total_size variable
    for input_file in "${file_array[@]}"; do
        [[ -z "$input_file" ]] && continue
        total_size=$((total_size + $(wc -c < "$input_file")))
    done

    # If the total size of selected files exceeds 1GB, show an error message and exit the function
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
  
        # Single file pipeline - show save dialog for output file and run compression pipeline for the selected file 
        input_file="${file_array[0]}"
        

        # Extract directory, base name, and extension for the selected file to construct the default output file name
        dir_name="$(dirname "$input_file")"
        base_name="$(basename "$input_file")"
        name_only="${base_name%.*}"
        extension="${base_name##*.}"


        # Auto-detect output extension based on input file type (PDFs will be compressed to PDF, others to .gz)
        local out_ext
        [[ "${extension,,}" == "pdf" ]] && out_ext="pdf" || out_ext="gz"
        

        # Show save dialog for output file with a default name based on the input file and run the appropriate compression pipeline based on the file type (PDFs use a different compression method)
        output_file=$(zenity --file-selection --save \
            --title="Save Compressed File As" \
            --filename="${dir_name}/${name_only}_compressed.${out_ext}" \
            --width=700 --height=500 2>/dev/null)
        [[ -z "$output_file" ]] && return 0
        

        # Run the appropriate compression pipeline based on the file type (PDFs use a different compression method)
        input_ext="${input_file##*.}"
        if [[ "${input_ext,,}" == "pdf" ]]; then
            bash "${SCRIPT_DIR}/compression/compress_pdf.sh" "$input_file" "$output_file"
        else
            bash "${SCRIPT_DIR}/compression/compress.sh" "$input_file" "$output_file"
        fi
    else
        # Multiple files pipeline - show save dialog for output file and run compression pipeline for each selected file, then show combined statistics at the end
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

            # Run the appropriate compression pipeline based on the file type (PDFs use a different compression method)
            input_ext="${input_file##*.}"
            if [[ "${input_ext,,}" == "pdf" ]]; then
                SUPPRESS_STATS=1 bash "${SCRIPT_DIR}/compression/compress_pdf.sh" "$input_file" "$output_file" # We set SUPPRESS_STATS to 1 to prevent the individual compression scripts from showing their own statistics dialogs, since we will show a combined statistics dialog at the end for all files
            else
                SUPPRESS_STATS=1 bash "${SCRIPT_DIR}/compression/compress.sh" "$input_file" "$output_file"     # Similar to the PDF case, we set SUPPRESS_STATS to 1 to prevent individual statistics dialogs and show a combined one at the end
            fi

            # Calculate statistics for this file and accumulate totals for all files to show in a combined statistics dialog at the end. We check if the output file was created successfully before trying to calculate its size, and only include it in the totals if it was created successfully. This way we can still show statistics for the files that were compressed successfully even if one of the files failed to compress.
            if [[ -f "$output_file" ]]; then
                original_size=$(wc -c < "$input_file")
                compressed_size=$(wc -c < "$output_file")
                
                total_original=$((total_original + original_size))
                total_compressed=$((total_compressed + compressed_size))
                file_count=$((file_count + 1))
            fi
        done

        # Show combined statistics for all files compressed successfully, or show an error message if no files were compressed successfully. 
        # We calculate the overall compression ratio based on the total original size and total compressed size of all the files that were compressed successfully, and show that in the statistics dialog at the end. 
        # If no files were compressed successfully, we show an error message instead of a statistics dialog.
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
    local decompress_exit=$?

    if [[ $decompress_exit -eq 0 ]] && [[ -f "$output_file" ]] && [[ -s "$output_file" ]]; then
        zenity --info \
            --title="Decompression Complete" \
            --text="File decompressed successfully.\n\nSaved to:\n${output_file}" \
            --width=400 2>/dev/null
    else
        zenity --error \
            --title="Decompression Failed" \
            --text="Failed to decompress file.\n\nPlease check if the file is a valid compressed archive." \
            --width=400 2>/dev/null
    fi
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




# handle_compress_single() {

#     return 0
# }

# handle_compress_multi() {
  
#     return 0
# }



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
    while true; do                     #show menu in a loop until user exits 
        local choice                   #local means this variable is only accessible within this function, prevents conflicts with other functions
        choice=$(show_menu)            #Here we call the show_menu function to display the menu and store the user's choice in the variable 'choice'
        [[ -z "$choice" ]] && exit 0   #If the user closes the menu or doesn't select anything, exit the script

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
