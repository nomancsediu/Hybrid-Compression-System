<div align="center">

# HFC Archiver: Hybrid File Compression System

**A Desktop Application for Linux**

**OS Lab Project — Group Submission**

[![nomancsediu](https://img.shields.io/badge/GitHub-nomancsediu-181717?logo=github)](https://github.com/nomancsediu)
[![supan-roy](https://img.shields.io/badge/GitHub-supan--roy-181717?logo=github)](https://github.com/supan-roy)
[![hossain-joy](https://img.shields.io/badge/GitHub-hossain--joy-181717?logo=github)](https://github.com/hossain-joy)
[![jeba234](https://img.shields.io/badge/GitHub-jeba234-181717?logo=github)](https://github.com/jeba234)
[![awalhsnmunna](https://img.shields.io/badge/GitHub-awalhsnmunna-181717?logo=github)](https://github.com/awalhsnmunna)

</div>

---

## 📌 About The Project

The **HFC Archiver: Hybrid File Compression System** is a pure Bash-based desktop application designed for Linux. It provides a simple, intuitive Graphical User Interface (GUI) to compress and decompress files and folders. The project utilizes a custom multi-stage compression pipeline combining Run-Length Encoding (RLE) and Lempel-Ziv-Welch (LZW) algorithms, resulting in high compression ratios without the need to rely on external heavyweight libraries.

---

## ✨ Key Features

- **Single & Multiple File Compression**: Intelligently detects file count and applies appropriate pipeline (rename dialog for single, auto-naming for multiple).
- **Custom Pipeline**: Compresses files using a powerful 3-stage pipeline (RLE → LZW → GZIP), achieving up to **84.9% compression ratio**.
- **PDF Optimization**: Compresses PDF files using Ghostscript (DCT + Flate) with selectable quality levels (screen, ebook, printer).
- **Folder Archiving**: Compresses entire folders with TAR + GZIP and offers to delete the original folder after compression.
- **File Encryption**: AES-256-CBC password encryption with PBKDF2 key derivation. Passwords require:
  - Minimum 6 characters
  - At least one letter
  - At least one number
- **File Decryption**: Incorrect password attempts allow immediate retry without exit.
- **Smart Decompression**: Auto-detects file format (.gz for files, .tar.gz for folders) and extracts to appropriate locations.
- **User-Friendly GUI**: Clean, modern Zenity-based interface — no terminal knowledge required.
- **Lightweight**: Written entirely in Bash with minimal dependencies.

---

## 📋 Main Menu Options

The HFC Archiver presents the following operations:

1. **Compress File** - Intelligently handles single or multiple files:
   - **Single file**: Shows save dialog to customize output name, displays individual results
   - **Multiple files**: Auto-names with `_compressed` suffix, shows combined statistics
   
2. **Compress Folder** - Archives and compresses entire directories:
   - Uses TAR + GZIP for optimal compression
   - Offers to delete original folder after compression
   - Displays compression statistics and ratio
   
3. **Decompress File/Archive** - Extracts compressed files:
   - Auto-detects `.gz` (single file) and `.tar.gz` (folder archive) formats
   - Folders extract to their original location
   - Single files prompt for output location
   
4. **Encrypt File** - Secure file encryption:
   - Uses AES-256-CBC encryption
   - Password validation required
   - Simplified success message (no file size display)
   
5. **Decrypt File** - Unlock encrypted files:
   - Supports unlimited password retry attempts
   - Allows immediate re-entry on incorrect password
   - Seamless user experience

---

## 🛠️ Tech Stack

| Layer       | Technology                        |
|-------------|-----------------------------------|
| Language    | Bash Shell Script                 |
| GUI         | Zenity (GTK-based)                |
| PDF Engine  | Ghostscript                       |
| Algorithms  | RLE, LZW, GZIP, DCT, Tar          |
| Platform    | Linux                             |

---

## ⚙️ Prerequisites

Before running the application, ensure you have the following installed on your Linux system:

- `bash`: Standard Unix shell.
- `zenity`: Used to render the graphical interfaces and file dialogues.
- `ghostscript` (`gs`): Required specifically for PDF compression/optimization.
- `tar` & `gzip`: Standard archiving and compression binaries.

On Debian/Ubuntu-based systems, you can install the dependencies via:
```bash
sudo apt update
sudo apt install bash zenity ghostscript tar gzip
```

---

## 🚀 Installation & Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nomancsediu/Hybrid-Compression-System.git
   cd Hybrid-Compression-System
   ```

2. **Make the scripts executable:**
   ```bash
   chmod +x main.sh
   chmod +x compression/*.sh decompression/*.sh
   ```

3. **Run the application:**
   ```bash
   ./main.sh
   ```

4. **Navigate the GUI:**
   
   When you launch HFC Archiver, a menu with 5 operations appears:
   
   - **Compress File**: 
     - Select 1 file → Custom rename dialog + individual statistics
     - Select multiple files → Auto-named with `_compressed` suffix + combined statistics
   
   - **Compress Folder**: 
     - Select a directory to archive and compress
     - Option to delete original folder after compression
   
   - **Decompress File/Archive**: 
     - Select `.gz` file (single file) → Choose output location
     - Select `.tar.gz` file (folder) → Auto-extracts to same directory
   
   - **Encrypt File**: 
     - Select file to encrypt
     - Enter password (6+ chars, min 1 letter, min 1 number)
     - Confirm password
   
   - **Decrypt File**: 
     - Select `.enc` file
     - Enter password (unlimited retries allowed)

---

## 🔐 Security Features

- **AES-256-CBC Encryption**: Military-grade encryption standard
- **PBKDF2 Key Derivation**: 100,000 iterations for strong key generation
- **Password Requirements**:
  - Minimum 6 characters
  - At least one alphabetic character (a-z, A-Z)
  - At least one numeric character (0-9)
- **Retry Support**: Wrong password attempts don't exit the application

---

## 📊 Compression Statistics

After compression, HFC Archiver displays:
- **Original Size**: Total bytes of uncompressed file(s)
- **Compressed Size**: Total bytes of compressed file(s)
- **Compression Ratio**: Percentage reduction (higher = better compression)

Example:
```
Files Compressed: 3
Total Original Size: 45,382,104 bytes
Total Compressed Size: 5,287,345 bytes
Compression Ratio: 88.3%
```

---

## 🧠 How It Works

### Single File Compression
- User selects one file from the file picker
- Save dialog appears to customize output filename
- File passes through 3-stage compression pipeline:
  1. **Run-Length Encoding (RLE)**: Removes repetitive consecutive characters
  2. **LZW Encoding**: Builds pattern dictionary and replaces sequences with codes
  3. **GZIP Compression**: Final compression at level 9
- Statistics displayed showing original size, compressed size, and ratio
- Output: `.gz` file (or `.pdf` for PDF input)

### Multiple File Compression
- User selects multiple files (Ctrl+Click or Shift+Click)
- Each file is compressed automatically with `_compressed` suffix
- No dialogs during compression
- Statistics combined and shown once:
  - Total files compressed
  - Sum of all original sizes
  - Sum of all compressed sizes
  - Overall compression ratio
- Output: Multiple `.gz` files in their respective directories

### Folder Compression
- User selects a directory to compress
- Entire folder structure is archived into a single `.tar` file
- Archive is compressed using TAR + GZIP (level 9):
  - TAR handles folder structure and metadata
  - GZIP provides efficient compression
- After compression:
  - Shows compression statistics
  - Asks user: **Keep original folder or delete?**
  - If deleted, only compressed `.tar.gz` remains
- Output: `.tar.gz` file in the same parent directory

### Single File Decompression
- User selects a `.gz` file
- System extracts using the reverse pipeline:
  - GZIP decompression
  - LZW decoding
  - RLE decoding
- User prompted to select output location and filename
- Original file restored

### Folder Decompression
- User selects a `.tar.gz` file
- System detects folder archive format
- Extracts directly to the same directory as the archive
- Recreates original folder structure
- User sees confirmation with extracted folder path

### PDF Compression
- User selects a `.pdf` file for compression
- Quality selection dialog appears:
  - **Screen** (72 DPI) - Smallest file, lowest quality
  - **Ebook** (150 DPI) - Recommended balance
  - **Printer** (300 DPI) - High quality
- Ghostscript applies compression:
  - DCT (lossy) to images
  - Flate (lossless) to text and fonts
- Output: Compressed PDF, fully readable without decompression

### File Encryption
- User selects a file to encrypt
- Password dialog appears (password must meet requirements)
- Encryption uses AES-256-CBC with PBKDF2 (100,000 iterations)
- Success message shown (no file size display to avoid confusion)
- Output: `.enc` file

### File Decryption
- User selects an encrypted `.enc` file
- Password dialog appears
- If password incorrect:
  - Error message shown
  - User can immediately retry without exiting
  - Unlimited retry attempts allowed
- On success: File decrypted and saved to chosen location

---

## 📁 Project Structure

```text
Hybrid-Compression-System/
├── main.sh                       # Main GUI entry point
├── README.md                     # Project documentation
├── compression/                  # Compression logic
│   ├── compress.sh               # Standard file compression pipeline coordinator
│   ├── compress_pdf.sh           # Ghostscript PDF optimizer
│   ├── lzw_encode.sh             # LZW encoder script
│   └── rle_encode.sh             # Run-Length encoder script
├── decompression/                # Decompression logic
│   ├── decompress.sh             # Standard pipeline decoder coordinator
│   ├── gzip_decompress.sh        # GZIP decompression script
│   ├── lzw_decode.sh             # LZW decoder script
│   ├── rle_decode.sh             # Run-Length decoder script
│   └── smart_gzip_decompress.sh  # Advanced extraction mapping
└── encryption/                   # Encryption/Decryption logic
    ├── encrypt.sh                # AES-256-CBC file encryption with password validation
    └── decrypt.sh                # AES-256-CBC file decryption with retry support
```

---

## 🎯 Usage Examples

### Compress a Single Text File
1. Launch HFC Archiver: `./main.sh`
2. Select "Compress File"
3. Choose a `.txt` file
4. Save dialog appears → customize filename → click Save
5. Compression begins
6. Statistics shown (original size, compressed size, ratio)

### Compress Multiple Files at Once
1. Select "Compress File"
2. Ctrl+Click to select multiple files (txt, pdf, doc, etc.)
3. All files compress automatically to `filename_compressed.gz`
4. Single combined statistics screen shows total ratio

### Compress an Entire Folder
1. Select "Compress Folder"
2. Choose a directory
3. Set output filename for the archive
4. After compression: asked "Keep original folder?"
5. Choose to keep or delete the original
6. Statistics displayed

### Encrypt Sensitive Files
1. Select "Encrypt File"
2. Choose a file
3. Set password (must have: 6+ chars, 1+ letter, 1+ number)
4. Confirm password
5. File encrypted as `.enc`

### Decrypt Protected Files
1. Select "Decrypt File"
2. Choose an `.enc` file
3. Enter password
4. If wrong: error shown, immediately retry
5. On success: file restored to chosen location

---

## ⚠️ Important Notes

- **Single files** use the 3-stage pipeline (RLE+LZW+GZIP) for maximum compression
- **Folders** use TAR+GZIP for faster, more reliable compression
- **PDFs** use Ghostscript compression; choose quality based on your needs
- **Encrypted files** cannot be read without the correct password
- **Passwords** are case-sensitive and require validation
- **Original files** are NOT deleted after compression (only optional for folders)


---

<div align="center">

Version 2.1 &nbsp;·&nbsp; Linux &nbsp;·&nbsp; Open Source

</div>
