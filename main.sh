#!/bin/bash
# main.sh — Hybrid Compression System GUI entry point
# Usage: ./main.sh

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dependency check
for cmd in zenity python3 gzip tar; do
    if ! command -v "$cmd" &>/dev/null; then
        zenity --error --title="Missing Dependency" \
            --text="Required command not found: ${cmd}\n\nInstall it and try again." \
            --width=400 2>/dev/null || echo "Missing: $cmd" >&2
        exit 1
    fi
done

show_menu() {
    zenity --list \
        --title="Hybrid Compression System" \
        --text="Select an operation:" \
        --column="Operation" \
        --width=500 --height=380 \
        --modal \
        "Compress File" \
        "Compress Folder" \
        "Decompress File/Archive" \
        "Encrypt File" \
        "Decrypt File" \
        "Exit" 2>/dev/null
}

handle_encrypt() {
    local input_file output_file dir_name name_only

    input_file=$(zenity --file-selection --title="Select File to Encrypt" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_file" ]] && return 0

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
    local input_file output_file dir_name name_only

    input_file=$(zenity --file-selection --title="Select File to Decrypt" --width=700 --height=500 2>/dev/null)
    [[ -z "$input_file" ]] && return 0

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
    local input_file dir_name base_name name_only ext output_file

    input_file=$(zenity --file-selection \
        --title="Select File to Compress" \
        --width=700 --height=500 2>/dev/null) || return 0
    [[ -z "$input_file" ]] && return 0

    dir_name="$(dirname "$input_file")"
    base_name="$(basename "$input_file")"
    name_only="${base_name%.*}"
    ext="${base_name##*.}"

    if [[ "${ext,,}" == "pdf" ]]; then
        output_file=$(zenity --file-selection --save \
            --title="Save Compressed PDF As" \
            --filename="${dir_name}/${name_only}_compressed.pdf" \
            --width=700 --height=500 2>/dev/null) || return 0
        [[ -z "$output_file" ]] && return 0
        bash "${SCRIPT_DIR}/compression/compress_pdf.sh" "$input_file" "$output_file"
    else
        output_file=$(zenity --file-selection --save \
            --title="Save Compressed File As" \
            --filename="${dir_name}/${name_only}_compressed.gz" \
            --width=700 --height=500 2>/dev/null) || return 0
        [[ -z "$output_file" ]] && return 0
        # Enforce .gz extension
        [[ "$output_file" != *.gz ]] && output_file="${output_file}.gz"
        bash "${SCRIPT_DIR}/compression/compress.sh" "$input_file" "$output_file"
    fi
}

handle_compress_folder() {
    local input_dir base_name output_file tmp_tar

    input_dir=$(zenity --file-selection --directory \
        --title="Select Folder to Compress" \
        --width=700 --height=500 2>/dev/null) || return 0
    [[ -z "$input_dir" ]] && return 0

    base_name="$(basename "$input_dir")"

    output_file=$(zenity --file-selection --save \
        --title="Save Compressed Archive As" \
        --filename="$(dirname "$input_dir")/${base_name}_compressed.tar.gz" \
        --width=700 --height=500 2>/dev/null) || return 0
    [[ -z "$output_file" ]] && return 0
    # Enforce .tar.gz extension
    [[ "$output_file" != *.tar.gz ]] && output_file="${output_file}.tar.gz"

    tmp_tar="$(mktemp --suffix=.tar)"
    trap "rm -f '$tmp_tar'" RETURN

    tar -cf "$tmp_tar" -C "$(dirname "$input_dir")" "$base_name"
    bash "${SCRIPT_DIR}/compression/compress.sh" "$tmp_tar" "$output_file"
}

handle_decompress() {
    local input_file dir_name base_name name_only output_file out_dir is_archive

    input_file=$(zenity --file-selection \
        --title="Select File to Decompress" \
        --width=700 --height=500 2>/dev/null) || return 0
    [[ -z "$input_file" ]] && return 0

    # Guard: only accept .gz files
    if [[ "$input_file" != *.gz ]]; then
        zenity --error --title="Unsupported Format" \
            --text="Only .gz and .tar.gz files are supported.\n\nSelected: $(basename "$input_file")" \
            --width=400 2>/dev/null
        return 0
    fi

    dir_name="$(dirname "$input_file")"
    base_name="$(basename "$input_file")"

    case "$base_name" in
        *.tar.gz) name_only="${base_name%.tar.gz}"; is_archive=1 ;;
        *.gz)     name_only="${base_name%.gz}";     is_archive=0 ;;
    esac

    if [[ "$is_archive" -eq 1 ]]; then
        out_dir=$(zenity --file-selection --directory \
            --title="Select Extraction Destination" \
            --filename="${dir_name}/" \
            --width=700 --height=500 2>/dev/null) || return 0
        [[ -z "$out_dir" ]] && return 0

        local tmp_tar
        tmp_tar="$(mktemp --suffix=.tar)"
        trap "rm -f '$tmp_tar'" RETURN

        bash "${SCRIPT_DIR}/decompression/decompress.sh" "$input_file" "$tmp_tar"
        tar -xf "$tmp_tar" -C "$out_dir"
        rm -f "$tmp_tar"

        zenity --info --title="Extraction Complete" \
            --text="Archive extracted to:\n${out_dir}" --width=400 2>/dev/null
    else
        output_file=$(zenity --file-selection --save \
            --title="Save Decompressed File As" \
            --filename="${dir_name}/${name_only}" \
            --width=700 --height=500 2>/dev/null) || return 0
        [[ -z "$output_file" ]] && return 0

        bash "${SCRIPT_DIR}/decompression/decompress.sh" "$input_file" "$output_file"
    fi
}

main() {
    while true; do
        local choice
        choice="$(show_menu)" || true

        case "$choice" in
            "Compress File")           handle_compress         ;;
            "Compress Folder")         handle_compress_folder  ;;
            "Decompress File/Archive") handle_decompress       ;;
            "Encrypt File")            handle_encrypt          ;;
            "Decrypt File")            handle_decrypt          ;;
            "Exit" | "")               exit 0                  ;;
        esac
    done
}

main
