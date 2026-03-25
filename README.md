# Hybrid File Compression System
**A Professional Desktop Application for Linux**

## Overview

The Hybrid File Compression System is a modern GUI-based compression tool that combines two powerful algorithms - Run-Length Encoding (RLE) and Huffman Coding - to achieve efficient lossless file compression. Built with Bash and Zenity, it provides an intuitive interface for compressing and decompressing files on Linux systems.

## Key Features

- **Professional GUI Interface** - Clean, modern design with centered dialogs
- **Two-Stage Compression** - Combines RLE and Huffman algorithms for better results
- **Real-Time Progress Tracking** - Visual feedback during compression/decompression
- **Detailed Statistics** - View compression ratios, file sizes, and processing time
- **Lossless Compression** - Original files are perfectly restored after decompression
- **Error Handling** - Comprehensive validation and user-friendly error messages
- **Cross-Compatible** - Works on any Linux distribution with Zenity installed

## System Requirements

- **Operating System:** Linux (tested on Kali Linux)
- **Shell:** Bash 4.0 or higher
- **GUI Toolkit:** Zenity
- **Utilities:** awk, sed, sort, uniq, zip, unzip
- **Recommended:** 512MB RAM, 100MB free disk space

## Installation

1. Clone or download the project:
```bash
cd /path/to/hybrid_compression
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. Verify Zenity is installed:
```bash
zenity --version
```

If not installed:
```bash
sudo apt-get install zenity  # Debian/Ubuntu
sudo yum install zenity      # RHEL/CentOS
```

## Quick Start

Launch the application:
```bash
./main.sh
```

The main menu provides five options:
1. **Compress File** - Select a file to compress
2. **Decompress File** - Restore a compressed file
3. **View Statistics** - See compression performance metrics
4. **About System** - Learn about the algorithms
5. **Exit Application** - Close the program

## How It Works

### Compression Process

```
Original File (e.g., document.txt)
         ↓
[Stage 1: Run-Length Encoding]
  - Identifies repetitive sequences
  - Converts "AAAAA" to "5A"
  - Reduces redundancy
         ↓
[Stage 2: Huffman Coding]
  - Analyzes character frequency
  - Assigns shorter codes to frequent characters
  - Creates compressed archive
         ↓
Compressed File (document.zip + document.zip.tree)
```

### Decompression Process

```
Compressed File (document.zip + document.zip.tree)
         ↓
[Stage 1: Huffman Decoding]
  - Reads tree file for code mapping
  - Decodes binary data to RLE format
         ↓
[Stage 2: Run-Length Decoding]
  - Expands "5A" back to "AAAAA"
  - Restores original structure
         ↓
Original File Restored (document_restored.txt)
```

## File Structure

```
hybrid_compression/
├── main.sh              # Main GUI application
├── compress.sh          # Compression workflow controller
├── decompress.sh        # Decompression workflow controller
├── stats.sh             # Statistics display module
├── rle_encode.sh        # Run-Length Encoding implementation
├── rle_decode.sh        # Run-Length Decoding implementation
├── huffman_encode.sh    # Huffman Coding implementation
├── huffman_decode.sh    # Huffman Decoding implementation
├── test_input.txt       # Sample test file
└── README.md            # This file
```

## Command Line Usage

For advanced users or automation:

**Compress a file:**
```bash
./compress.sh input.txt output.zip
```

**Decompress a file:**
```bash
./decompress.sh output.zip restored.txt
```

**Note:** Tree files (.tree) are automatically created and required for decompression.

## Algorithm Details

### Run-Length Encoding (RLE)

RLE compresses data by replacing consecutive identical characters with a count and the character itself.

**Example:**
- Input: `AAAAABBBCC`
- Output: `5A3B2C`
- Best for: Files with repetitive patterns

### Huffman Coding

Huffman Coding uses variable-length codes based on character frequency. Frequent characters get shorter codes.

**Example:**
- Character 'E' (frequent): `10`
- Character 'Z' (rare): `111010`
- Best for: Text files with varying character distribution

## Performance Metrics

The system tracks and displays:
- **Original Size** - Size of input file in bytes
- **Compressed Size** - Size of output file + tree file in bytes
- **Space Saved** - Difference between original and compressed
- **Compression Ratio** - Percentage of size reduction
- **Processing Time** - Time taken for operation in seconds

## Best Practices

1. **File Types:** Works best with text files (.txt, .log, .csv, .json, .xml)
2. **File Size:** Optimal for files between 1KB and 100MB
3. **Backup:** Keep original files until decompression is verified
4. **Storage:** Store .zip and .tree files in the same directory
5. **Testing:** Use the included test_input.txt for initial testing

## Troubleshooting

**Problem:** Window doesn't appear centered
- **Solution:** Ensure Zenity is updated to the latest version

**Problem:** Compression ratio is negative
- **Solution:** File may not have repetitive patterns; RLE works best with redundant data

**Problem:** Tree file missing during decompression
- **Solution:** Both .zip and .tree files must be present in the same location

**Problem:** Permission denied error
- **Solution:** Run `chmod +x *.sh` to make scripts executable

## Technical Specifications

- **Language:** Bash Shell Script
- **GUI Framework:** Zenity (GTK-based)
- **Compression Format:** ZIP with custom RLE preprocessing
- **Encoding:** UTF-8 compatible
- **Maximum File Size:** Limited by available system memory
- **Supported Platforms:** Linux (all distributions)

## Project Structure

This project demonstrates:
- Shell scripting best practices
- Modular code architecture
- GUI development with Zenity
- Algorithm implementation in Bash
- File I/O operations
- Error handling and validation
- User experience design

## Future Enhancements

Potential improvements:
- Support for multiple file compression
- Drag-and-drop interface
- Compression level selection
- Password protection
- File integrity verification (checksums)
- Batch processing mode

## License

This project is open-source and available for educational purposes.

## Developer

**Developed by Python Lover**

For questions, suggestions, or bug reports, please refer to the project repository.

---

**Version:** 1.0  
**Last Updated:** 2024  
**Platform:** Linux  
**Status:** Production Ready
