#!/bin/bash
# gzip_decompress.sh — delegates to smart_gzip_decompress.sh
# Kept for backwards compatibility.
# Usage: ./gzip_decompress.sh <input_file> <output_file>

set -euo pipefail
[[ "$#" -ne 2 ]] && { echo "Usage: $0 <input_file> <output_file>" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/smart_gzip_decompress.sh" "$1" "$2"
