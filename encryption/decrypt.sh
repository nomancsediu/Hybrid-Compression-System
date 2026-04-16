#!/bin/bash
#
# decrypt.sh
# Password-based AES-256-CBC decryption.
#
# Usage: ./decrypt.sh <input_file> <output_file>

main() {
    local input_file="$1"
    local output_file="$2"

    if [[ ! -f "$input_file" ]]; then
        zenity --error --title="Error" --text="File not found:\n${input_file}" --width=400
        exit 1
    fi

    local password

    while true; do
        password=$(zenity --password \
            --title="Enter Decryption Password" \
            --width=400 2>/dev/null)
        [[ -z "$password" ]] && exit 0

        if openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
            -in "$input_file" -out "$output_file" \
            -pass pass:"$password" 2>/dev/null; then
            zenity --info \
                --title="Decryption Complete" \
                --text="File decrypted successfully.\n\nSaved to:\n${output_file}" \
                --width=400 2>/dev/null
            return 0
        fi

        rm -f "$output_file" 2>/dev/null || true
        zenity --error --title="Incorrect Password" \
            --text="Incorrect password. Try again." --width=400
    done
}

main "$@"
