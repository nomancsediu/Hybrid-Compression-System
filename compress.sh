#!/bin/bash
# Compression: RLE -> Huffman

input_file="$1"
output_file="$2"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
temp_rle=$(mktemp)

(
echo "10"; echo "# Applying Run-Length Encoding..."
bash "$script_dir/rle_encode.sh" "$input_file" "$temp_rle"

echo "60"; echo "# Applying Huffman Encoding..."
bash "$script_dir/huffman_encode.sh" "$temp_rle" "$output_file"

echo "100"; echo "# Done!"
) | zenity --progress --title="Compressing" --text="Please wait..." --percentage=0 --width=400 --auto-close

rm -f "$temp_rle"

original_size=$(wc -c < "$input_file")
compressed_size=$(wc -c < "$output_file")
ratio=$(awk "BEGIN {printf \"%.1f\", (1 - $compressed_size/$original_size) * 100}")

zenity --info --title="Compression Complete" \
    --text="<span font='12' weight='bold'>File compressed successfully.</span>\n\nOriginal Size:   <b>$original_size bytes</b>\nCompressed Size: <b>$compressed_size bytes</b>\nRatio:           <b>${ratio}%</b>" \
    --width=400
