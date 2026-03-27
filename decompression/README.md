# Decompression Module

**Author**: Supan Roy

This directory contains all the scripts needed to decompress files that were compressed by the Hybrid Compression System. The decompression process reverses the compression pipeline to restore original files faithfully.

## Overview

The decompression system intelligently detects the compression method and file type, then applies the appropriate decompression algorithm to restore the original data.

### Supported Compression Methods
- **GZIP (RLE+LZW+GZIP Pipeline)**: For text and highly compressible files
- **LZW (Lempel-Ziv-Welch)**: Standalone LZW decompression
- **RLE (Run-Length Encoding)**: Standalone RLE decompression
- **PDF**: PDF decompression using Ghostscript

---

## Directory Structure

```
decompression/
├── README.md                       # This file - Documentation
├── decompress.sh                   # Main entry point (orchestrator)
├── smart_gzip_decompress.sh       # Smart GZIP decompression with auto-detection
├── gzip_decompress.sh             # Full pipeline GZIP decompression
├── lzw_decode.sh                  # LZW decoder
├── rle_decode.sh                  # RLE decoder
└── decompress_pdf.sh              # PDF decompression
```

---

## Decompression Pipeline Logic

### For GZIP Compressed Files (.gz)

The GZIP decompression process reverses the compression pipeline in **reverse order**:

```
Compressed File (GZIP)
    ↓
gunzip (decompress GZIP layer)
    ↓
LZW Decode (reverse LZW encoding)
    ↓
RLE Decode (reverse RLE encoding)
    ↓
Original File
```

### For Other Compressed Files

- **RLE Only**: RLE Decode → Original File
- **LZW Only**: LZW Decode → Original File
- **PDF**: Ghostscript reconversion → Original PDF

---

## Script Details

### 1. **decompress.sh** (Main Orchestrator)

**Purpose**: Single entry point for all decompression operations

**Usage**:
```bash
./decompress.sh <input_file> <output_file> <method>
```

**Parameters**:
- `<input_file>`: Path to the compressed file
- `<output_file>`: Path where the decompressed file will be saved
- `<method>`: Decompression method (gzip, lzw, rle, pdf)

**Example**:
```bash
./decompress.sh myfile_compressed.gz myfile_restored.txt gzip
./decompress.sh myfile_compressed.lzw myfile.txt lzw
./decompress.sh myfile_compressed.rle myfile.txt rle
./decompress.sh myfile_compressed.pdf myfile_restored.pdf pdf
```

**How It Works**:
- Acts as a router that dispatches to the appropriate decompression script
- Validates the number of arguments
- Routes to the correct decoder based on the `<method>` parameter

---

### 2. **smart_gzip_decompress.sh** (Intelligent GZIP Decompression)

**Purpose**: Automatically detects whether a GZIP file contains LZW+RLE encoded data or just plain GZIP data, and decompresses accordingly.

**Usage**:
```bash
./smart_gzip_decompress.sh <input_file> <output_file>
```

**Parameters**:
- `<input_file>`: GZIP compressed file
- `<output_file>`: Destination for decompressed file

**How It Works**:
1. Decompresses the GZIP layer using `gunzip`
2. **Detects** if the decompressed content is LZW-encoded by checking if all initial lines contain only numeric values
3. **If LZW encoded** (detected by numeric lines):
   - Decodes LZW layer
   - Decodes RLE layer
4. **If plain GZIP** (not numeric):
   - Copies the decompressed content directly
5. Cleans up temporary files automatically

**Example**:
```bash
# For text files that were compressed with full pipeline
./smart_gzip_decompress.sh document_compressed.gz document.txt

# For binary files (like .docx) that were GZIP only
./smart_gzip_decompress.sh presentation_compressed.gz presentation.docx
```

**Advantages**:
- Automatically detects compression method
- Handles both pipeline and plain GZIP files
- Prevents errors from attempting wrong decompression

---

### 3. **gzip_decompress.sh** (Full Pipeline GZIP Decompression)

**Purpose**: Explicitly decompresses files that used the full RLE+LZW+GZIP pipeline

**Usage**:
```bash
./gzip_decompress.sh <input_file> <output_file>
```

**Parameters**:
- `<input_file>`: GZIP compressed file
- `<output_file>`: Destination for decompressed file

**How It Works**:
1. Decompresses GZIP layer: `gunzip -c input > temp1`
2. Decodes LZW layer: `lzw_decode.sh temp1 > temp2`
3. Decodes RLE layer: `rle_decode.sh temp2 > output`
4. Cleans up temporary files

**Example**:
```bash
./gzip_decompress.sh article_compressed.gz article.txt
```

**When to Use**:
- When you know the file was compressed with the full RLE+LZW+GZIP pipeline
- For guaranteed correct decompression of text files
- Note: `smart_gzip_decompress.sh` is preferred as it auto-detects

---

### 4. **lzw_decode.sh** (LZW Decoder)

**Purpose**: Reverses LZW (Lempel-Ziv-Welch) encoding

**Usage**:
```bash
./lzw_decode.sh <input_file> <output_file>
```

**Parameters**:
- `<input_file>`: LZW-encoded file (one integer code per line)
- `<output_file>`: Destination for decoded file

**LZW Algorithm (Decoding)**:
- Rebuilds the dictionary identically to how it was built during encoding
- Reads numeric codes from input, one per line
- Reconstructs the original byte sequence from dictionary lookups
- Dictionary starts with entries 0-255 for all single bytes
- Dictionary expands as new sequences are encountered (256+)

**Example**:
```bash
./lzw_decode.sh encoded.lzw decoded.txt
```

**Implementation Details**:
- Uses AWK for efficient dictionary management
- Handles up to 4096 dictionary entries (256-4096)
- Maintains state across lines using AWK arrays

---

### 5. **rle_decode.sh** (RLE Decoder)

**Purpose**: Reverses Run-Length Encoding

**Usage**:
```bash
./rle_decode.sh <input_file> <output_file>
```

**Parameters**:
- `<input_file>`: RLE-encoded file
- `<output_file>`: Destination for decoded file

**RLE Algorithm (Decoding)**:
- Format: `<count><character>` for sequences of 3+ identical characters
- Single/double occurrences are stored as-is without count prefix
- Examples: `11A` → 11 A's, `BB` → 2 B's, `5X` → 5 X's

**Decoding Process**:
1. Parse each line character by character
2. When a digit is found, collect all consecutive digits to form the count
3. Convert count string to **numeric value** (important for proper loop iteration)
4. Get the character after the count
5. Output the character repeated by the count
6. For non-digit characters, output them as-is

**Example**:
```bash
# Input: 11ABBBCCCC
# Output: AAAAAAAAAABBBBCCCC

./rle_decode.sh encoded.rle decoded.txt
```

**Important Bug Fix**:
The decoder uses numeric count calculation (`count = count * 10 + digit`) instead of string concatenation to ensure correct loop iterations:
```awk
count = 0
while (i <= n && substr(line, i, 1) ~ /[0-9]/) {
    count = count * 10 + substr(line, i, 1)  # Numeric calculation
    i++
}
```

---

### 6. **decompress_pdf.sh** (PDF Decompression)

**Purpose**: Decompresses PDF files using Ghostscript with high quality settings

**Usage**:
```bash
./decompress_pdf.sh <input_file> <output_file>
```

**Parameters**:
- `<input_file>`: Compressed PDF file
- `<output_file>`: Destination for decompressed PDF

**How It Works**:
- Uses Ghostscript (`gs`) to reprocess the PDF
- Applies printer quality settings (300 DPI) to restore quality
- Flattens and reoptimizes the PDF structure

**Example**:
```bash
./decompress_pdf.sh report_compressed.pdf report_restored.pdf
```

**Requirements**:
- Ghostscript must be installed: `sudo apt install ghostscript`

---

## Complete Workflow Example

### Scenario: Compressing and Decompressing a Text Document

**Step 1: Compress (in compression folder)**
```bash
bash compression/compress.sh myjournal.txt myjournal_compressed.gz
# Output: RLE → LZW → GZIP pipeline
# Result: myjournal_compressed.gz
```

**Step 2: Decompress (in decompression folder)**
```bash
bash decompression/decompress.sh myjournal_compressed.gz myjournal_restored.txt gzip
```

**Step 3: Verify**
```bash
diff myjournal.txt myjournal_restored.txt
# No output = files are identical ✓
```

---

## Performance Characteristics

| File Type | Compression Method | Best For | Compression Ratio |
|-----------|-------------------|----------|-------------------|
| Plain Text | RLE+LZW+GZIP | Documents, logs, code | 30-70% reduction |
| Already Compressed | GZIP only | .docx, .jpg, .zip | 5-15% reduction |
| PDFs | Ghostscript | PDF documents | 40-60% reduction |
| Binary Data | GZIP only | Executables, archives | Variable |

---

## Error Handling

### Common Errors and Solutions

**Error: "Ghostscript (gs) not installed"**
```bash
sudo apt install ghostscript
```

**Error: "Unknown method"**
- Ensure method is one of: `gzip`, `lzw`, `rle`, `pdf`
- Check spelling and capitalization

**Error: "File not found"**
- Verify the input file path exists
- Use absolute paths if relative paths fail

**Error: "Decompression failed"**
- Ensure the correct decompression method is used
- Verify the file is actually compressed with that method
- Check file integrity (not corrupted)

---

## Integration with GUI

The decompression scripts are integrated into the main GUI (`main.sh`):

1. Run: `bash main.sh`
2. Select "Decompress File"
3. Choose your compressed file
4. Select the decompression method:
   - **GZIP (RLE+LZW+GZIP Pipeline)** - for text files
   - **RLE** - for RLE-only compressed files
   - **LZW** - for LZW-only compressed files
   - **PDF** - for PDF files
5. Choose output location
6. File is decompressed automatically

---

## Testing

To test the decompression system:

```bash
# Create a test file
echo "AAAAAABBBBBBCCCCCCCCC" > test.txt

# Compress it (from compression folder)
bash compression/compress.sh test.txt test_compressed.gz

# Decompress it
bash decompression/decompress.sh test_compressed.gz test_restored.txt gzip

# Verify
diff test.txt test_restored.txt
echo $?  # Should output 0 (success)
```

---

## Key Algorithms Summary

### RLE (Run-Length Encoding)
- **Compression**: Replaces 3+ identical consecutive characters with `<count><char>`
- **Decompression**: Expands `<count><char>` back to original characters
- **Best for**: Text with repeated characters

### LZW (Lempel-Ziv-Welch)
- **Compression**: Builds dictionary of frequent sequences, replaces with codes
- **Decompression**: Rebuilds identical dictionary from codes, reconstructs sequences
- **Best for**: General-purpose compression

### GZIP
- **Compression**: Industry-standard deflate compression
- **Decompression**: Reverses compression layers
- **Best for**: Final compression stage

---

## Version History

- **v1.0** (March 27, 2026): Initial release with smart detection and RLE fix

---

## Support

For issues or questions:
1. Check this documentation
2. Review the script comments in the source files
3. Test with example files from the main directory
4. Check file permissions: `chmod +x *.sh`
