#!/bin/bash
# Hybrid Compression System

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while true; do
    choice=$(zenity --list \
        --title="Hybrid Compression System" \
        --text="Select an operation" \
        --width=500 --height=250 \
        --modal \
        --column="Operation" \
        "Compress File" \
        "Exit")

    case "$choice" in
        "Compress File")
            input_file=$(zenity --file-selection --title="Select File to Compress")
            [ -z "$input_file" ] && continue

            base_name=$(basename "$input_file")
            dir_name=$(dirname "$input_file")
            name_only="${base_name%.*}"

            output_file=$(zenity --file-selection --save \
                --title="Save As" \
                --filename="${dir_name}/${name_only}.zip")
            [ -z "$output_file" ] && continue

            bash "$script_dir/compress.sh" "$input_file" "$output_file"
            ;;

        "Exit"|"")
            exit 0
            ;;
    esac
done
