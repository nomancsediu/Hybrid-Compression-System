#!/bin/bash
#
# encrypt.sh
# Password-based AES-256-CBC encryption for compressed files.
#
# Usage: ./encrypt.sh <input_file> <output_file>

set -euo pipefail

validate_password() {
    local password="$1"
    
    # Check minimum length (6 characters)
    if [[ ${#password} -lt 6 ]]; then
        zenity --error --title="Invalid Password" \
            --text="Password must be at least 6 characters long." --width=400
        return 1
    fi
    
    # Check for at least one letter
    if ! [[ "$password" =~ [a-zA-Z] ]]; then
        zenity --error --title="Invalid Password" \
            --text="Password must contain at least one letter." --width=400
        return 1
    fi
    
    # Check for at least one number
    if ! [[ "$password" =~ [0-9] ]]; then
        zenity --error --title="Invalid Password" \
            --text="Password must contain at least one number." --width=400
        return 1
    fi
    
    return 0
}

main() {
    local input_file="$1"
    local output_file="$2"

    if [[ ! -f "$input_file" ]]; then
        zenity --error --title="Error" --text="File not found:\n${input_file}" --width=400
        exit 1
    fi

    local password confirm

    while true; do
        password=$(zenity --password \
            --title="Set Encryption Password" \
            --width=400 2>/dev/null)
        [[ -z "$password" ]] && exit 0

        if ! validate_password "$password"; then
            continue
        fi

        confirm=$(zenity --password \
            --title="Confirm Password" \
            --width=400 2>/dev/null)

        if [[ "$password" != "$confirm" ]]; then
            zenity --error --title="Error" --text="Passwords do not match." --width=400
            continue
        fi

        break
    done

    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
        -in "$input_file" -out "$output_file" \
        -pass pass:"$password"

    zenity --info \
        --title="Encryption Complete" \
        --text="File encrypted successfully." \
        --width=400 2>/dev/null
}

main "$@"
