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

The **Hybrid File Compression System** is a desktop application for Linux that provides a simple, intuitive Graphical User Interface (GUI) to compress and decompress files and folders. It uses a custom multi-stage compression pipeline combining Run-Length Encoding (RLE) and Lempel-Ziv-Welch (LZW) algorithms followed by GZIP, achieving high compression ratios on text-heavy and repetitive data without relying on external heavyweight libraries.

The pipeline is fully binary-safe — it correctly handles all file types including binary files, tar archives, and files containing null bytes or digit characters.

---

## ✨ Key Features

- **Binary-Safe Pipeline**: Compresses any file type (text, binary, archives) using a 3-stage pipeline (RLE → LZW → GZIP).
- **PDF Optimization**: Compresses PDF files directly using Ghostscript (DCT + Flate), no decompression step needed.
- **Folder Archiving**: Packages folders into a `.tar` archive and passes it through the full pipeline, producing a single `.tar.gz` output.
- **User-Friendly GUI**: Simple graphical interface built with Zenity — no terminal knowledge required.
- **Real Progress Feedback**: Each compression/decompression stage reports live progress to the UI.
- **Extension Enforcement**: Output files always carry the correct `.gz` or `.tar.gz` extension regardless of what the user types in the save dialog.
- **Startup Dependency Check**: The application checks for all required tools on launch and shows a clear error if any are missing.
- **Lightweight**: Written entirely in Bash with Python 3 used inline for binary-safe encode/decode logic.

---

## 🛠️ Tech Stack

| Layer       | Technology                              |
|-------------|-----------------------------------------|
| Language    | Bash Shell Script                       |
| Encode/Decode | Python 3 (inline, no external files) |
| GUI         | Zenity (GTK-based)                      |
| PDF Engine  | Ghostscript                             |
| Algorithms  | RLE, LZW, GZIP, DCT, Tar               |
| Platform    | Linux                                   |

---

## ⚙️ Prerequisites

Before running the application, ensure the following are installed on your Linux system:

- `bash` — Standard Unix shell
- `python3` — Used for binary-safe RLE and LZW encode/decode
- `zenity` — Renders the graphical interface and file dialogs
- `ghostscript` (`gs`) — Required for PDF compression only
- `tar` & `gzip` — Standard archiving and compression utilities

On Debian/Ubuntu-based systems:
```bash
sudo apt update
sudo apt install bash python3 zenity ghostscript tar gzip
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
   chmod +x main.sh compression/*.sh decompression/*.sh
   ```

3. **Run the application:**
   ```bash
   ./main.sh
   ```

4. **Navigate the GUI:**
   - **Compress File** — Select any file. PDF files are routed to Ghostscript; all other files go through the RLE → LZW → GZIP pipeline.
   - **Compress Folder** — Select a directory. It is packaged into a `.tar` archive and passed through the full pipeline, producing a `.tar.gz` output.
   - **Decompress File/Archive** — Select a `.gz` file to restore the original file, or a `.tar.gz` file to extract the original folder hierarchy to a chosen destination.

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

### Compression Pipeline (Text / Binary / Archive Files)

All non-PDF files pass through a 3-stage pipeline:

```
Input File  →  RLE Encode  →  LZW Encode  →  GZIP (level 9)  →  .gz Output
```

**Stage 1 — Run-Length Encoding (RLE)**
Scans the raw bytes of the file and replaces consecutive repeated bytes with a 2-byte token: `[count][byte]`. The count is capped at 255 per run. Every byte — including digits, null bytes, and special characters — is encoded uniformly, making the scheme fully binary-safe and free of digit-ambiguity issues present in text-based RLE.

**Stage 2 — LZW Encoding**
Builds a pattern dictionary starting with all 256 single-byte entries. As it scans the RLE output, recurring byte sequences are replaced with 16-bit integer codes. The dictionary grows up to 65,535 entries. The output is a binary file containing a 4-byte code count header followed by packed big-endian 16-bit codes.

**Stage 3 — GZIP Compression**
The LZW-encoded binary is compressed at level 9 using standard `gzip`, producing the final `.gz` output.

### Decompression Pipeline

The reverse pipeline is applied in exact reverse order:

```
.gz Input  →  GZIP Decompress  →  LZW Decode  →  RLE Decode  →  Original File
```

For `.tar.gz` archives, after the pipeline restores the `.tar` file, `tar` extracts the original folder hierarchy to the chosen destination.

### PDF Compression

PDF files are handled separately using Ghostscript with three selectable quality levels:

| Level   | DPI  | Description                        |
|---------|------|------------------------------------|
| screen  | 72   | Smallest file size, lowest quality |
| ebook   | 150  | Balanced — recommended             |
| printer | 300  | High quality                       |

Ghostscript applies **DCT (Discrete Cosine Transform)** to compress embedded images (lossy) and **Flate encoding** to compress text and fonts (lossless). The output is a fully valid, smaller `.pdf` file — no decompression step is required.

---

## 📁 Project Structure

```text
Hybrid-Compression-System/
├── main.sh                         # GUI entry point — dependency check, menu, routing
├── README.md                       # Project documentation
├── compression/
│   ├── compress.sh                 # RLE → LZW → GZIP pipeline coordinator
│   ├── compress_pdf.sh             # Ghostscript PDF optimizer
│   ├── rle_encode.sh               # Binary-safe RLE encoder (Python 3 inline)
│   └── lzw_encode.sh               # Binary-safe LZW encoder, packed 16-bit output (Python 3 inline)
└── decompression/
    ├── decompress.sh               # Decompression coordinator with progress UI
    ├── smart_gzip_decompress.sh    # Full reverse pipeline: GZIP → LZW → RLE
    ├── rle_decode.sh               # Binary-safe RLE decoder (Python 3 inline)
    ├── lzw_decode.sh               # Binary-safe LZW decoder, packed 16-bit input (Python 3 inline)
    └── gzip_decompress.sh          # Legacy wrapper — delegates to smart_gzip_decompress.sh
```

---

## 🔒 Design Decisions

**Why Python 3 for RLE and LZW?**
The original implementation used `awk` for encoding and decoding. `awk` processes input line-by-line as text, which means it cannot handle binary files, tar archives, or files containing null bytes. It also introduced a digit-ambiguity bug where digits in the original data were misread as RLE run counts during decoding. Python 3 reads and writes raw bytes, is available on all modern Linux systems, and is embedded inline inside the shell scripts — no separate `.py` files are needed.

**Why packed 16-bit binary codes for LZW?**
The original implementation wrote one integer per line as ASCII text. For a file producing thousands of LZW codes, this inflated the intermediate file size significantly before GZIP. Packing codes as big-endian 16-bit integers reduces the intermediate size by roughly 3–5× compared to ASCII integers, giving GZIP less work to do and improving overall compression ratio.

**Why enforce output file extensions?**
Zenity's save dialog does not enforce file extensions. If a user saves a compressed file without typing `.gz`, the decompression handler cannot identify the file format and rejects it. The application now automatically appends `.gz` or `.tar.gz` to the output path if the user omits it.

---

<div align="center">

Version 1.1 &nbsp;·&nbsp; Linux &nbsp;·&nbsp; Open Source

</div>
