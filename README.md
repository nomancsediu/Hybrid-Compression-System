<div align="center">

# Hybrid File Compression System

**A Desktop Application for Linux**

**OS Lab Project — Group Submission**

[![nomancsediu](https://img.shields.io/badge/GitHub-nomancsediu-181717?logo=github)](https://github.com/nomancsediu)
[![supan-roy](https://img.shields.io/badge/GitHub-supan--roy-181717?logo=github)](https://github.com/supan-roy)
[![hossain-joy](https://img.shields.io/badge/GitHub-hassain--joy-181717?logo=github)](https://github.com/hassain-joy)
[![jeba234](https://img.shields.io/badge/GitHub-jeba234-181717?logo=github)](https://github.com/jeba234)

</div>

---

## Key Features

- Compresses any text-based file using a 3-stage pipeline (RLE → LZW → GZIP)
- Compresses PDF files using Ghostscript (DCT + Flate)
- Simple GUI built with Zenity — no terminal knowledge required
- Achieves up to **84.9% compression ratio**
- Pure Bash — no external compression libraries

---

## Tech Stack

| Layer       | Technology                        |
|-------------|-----------------------------------|
| Language    | Bash Shell Script                 |
| GUI         | Zenity (GTK-based)                |
| PDF Engine  | Ghostscript                       |
| Algorithms  | RLE, LZW, GZIP, DCT               |
| Platform    | Linux                             |

---

## How It Works

### For Text Files

When a text-based file is selected, it passes through a 3-stage pipeline. In the first stage, Run-Length Encoding (RLE) scans the file and replaces consecutive repeated characters with a count followed by the character — for example, `AAAAA` becomes `5A`. This reduces repetitive data before any dictionary-based compression is applied.

In the second stage, LZW encoding builds a pattern dictionary from the RLE output and replaces recurring sequences with short integer codes. Finally, in the third stage, GZIP compresses the LZW-encoded output at level 9, producing the final `.gz` file.

### For PDF Files

PDF files are handled separately using Ghostscript. It applies DCT (Discrete Cosine Transform) to compress embedded images in a lossy manner, while text and fonts are compressed losslessly using Flate encoding. The output is a fully valid, smaller `.pdf` file — no decompression step is needed.

---

<div align="center">

Version 1.0 &nbsp;·&nbsp; Linux &nbsp;·&nbsp; Open Source

</div>
