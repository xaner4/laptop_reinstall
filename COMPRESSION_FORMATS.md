# Compression Formats Quick Reference

## Supported Archive Formats in tar_install.sh

This guide provides a quick reference for all compression formats supported by the enhanced `unpack()` function.

## Format Overview

| Format | Extension(s) | Tool Required | Use Case |
|--------|-------------|---------------|----------|
| Gzip Tarball | `.tar.gz`, `.tgz` | `tar` | Most common, good compression |
| Bzip2 Tarball | `.tar.bz2`, `.tbz2` | `tar` | Better compression than gzip |
| XZ Tarball | `.tar.xz`, `.txz` | `tar`, `xz` | Best compression for tarballs |
| Zstandard Tarball | `.tar.zst`, `.tzst` | `tar`, `zstd` | Fast with good compression |
| Plain Tarball | `.tar` | `tar` | No compression, fast |
| ZIP | `.zip` | `unzip` | Cross-platform archives |
| Gzip | `.gz` | `gunzip` | Single file compression |
| Bzip2 | `.bz2` | `bunzip2` | Single file compression |
| XZ | `.xz` | `unxz` | Single file compression |
| Zstandard | `.zst` | `unzstd` | Single file compression |
| 7-Zip | `.7z` | `7z` | High compression ratio |
| RAR | `.rar` | `unrar` | Proprietary format |

## Detailed Format Information

### Tar-based Formats

#### 1. **tar.gz / .tgz** (Gzip)
- **Most widely used** compression format
- Good balance of speed and compression
- Universal support across platforms
- **Compression ratio:** ~60-70%
- **Speed:** Fast

```bash
# Example usage in script
unpack "${download_url}" 0 binary_name
```

#### 2. **tar.bz2 / .tbz2** (Bzip2)
- Better compression than gzip
- Slower compression/decompression
- **Compression ratio:** ~70-75%
- **Speed:** Slower than gzip

#### 3. **tar.xz / .txz** (XZ/LZMA)
- Best compression ratio for tar archives
- Significantly slower than gzip
- Popular for distributing large software packages
- **Compression ratio:** ~75-80%
- **Speed:** Slowest

#### 4. **tar.zst / .tzst** (Zstandard)
- Modern compression algorithm
- Excellent balance: fast + good compression
- Increasingly popular for software distribution
- **Compression ratio:** ~70-75%
- **Speed:** Very fast

#### 5. **.tar** (Uncompressed)
- No compression, just archiving
- Fastest extraction
- Large file size
- **Compression ratio:** 0%
- **Speed:** Fastest

### Non-Tar Formats

#### 6. **.zip** (ZIP)
- Most common on Windows
- Built-in support on most operating systems
- Can store file permissions (with limitations)
- **Note:** Strip-components behavior is emulated

```bash
# The script handles sublevel for zip files automatically
unpack "${download_url}" 1 file.exe
```

#### 7. **.gz** (Gzip - Single File)
- Compresses single files only
- Often used for compressing text files
- Common for logs: `access.log.gz`

```bash
# Decompresses to specified filename
unpack "file.gz" 0 output_filename
```

#### 8. **.bz2** (Bzip2 - Single File)
- Better compression than .gz for single files
- Slower than gzip
- Less common than .gz

#### 9. **.xz** (XZ - Single File)
- Excellent compression for single files
- Slow compression, moderate decompression
- Popular in Linux distributions

#### 10. **.zst** (Zstandard - Single File)
- Modern, fast compression
- Growing adoption
- Good compression with fast speed

#### 11. **.7z** (7-Zip)
- Excellent compression ratios
- Requires p7zip package
- Cross-platform support
- **Compression ratio:** ~75-80%

```bash
# Requires: sudo dnf install p7zip p7zip-plugins
unpack "archive.7z" 0 binary_name
```

#### 12. **.rar** (RAR)
- Proprietary format
- Good compression
- Common on Windows
- Requires unrar (free extractor)

```bash
# Requires: sudo dnf install unrar
unpack "archive.rar" 0 binary_name
```

## Compression Comparison

### Speed Ranking (Fastest to Slowest)
1. tar (no compression)
2. zstd / tar.zst
3. gzip / tar.gz
4. bzip2 / tar.bz2
5. xz / tar.xz
6. 7z

### Compression Ratio Ranking (Best to Worst)
1. xz / tar.xz / 7z (~75-80%)
2. tar.zst / tar.bz2 (~70-75%)
3. tar.gz (~60-70%)
4. zip (~60-65%)
5. tar (0%)

### Universal Compatibility Ranking
1. tar.gz (nearly universal)
2. zip (universal)
3. tar.bz2 (very common)
4. tar.xz (common on Linux)
5. tar.zst (growing adoption)
6. 7z (requires additional tools)
7. rar (requires additional tools)

## Installation Commands for Required Tools

### Fedora / RHEL / CentOS
```bash
# Install all supported compression tools
sudo dnf install wget tar unzip bzip2 xz zstd p7zip p7zip-plugins unrar

# Minimal (most common formats)
sudo dnf install wget tar unzip bzip2 xz
```

### Debian / Ubuntu
```bash
# Install all supported compression tools
sudo apt install wget tar unzip bzip2 xz-utils zstd p7zip-full unrar

# Minimal (most common formats)
sudo apt install wget tar unzip bzip2 xz-utils
```

### Arch Linux
```bash
# Install all supported compression tools
sudo pacman -S wget tar unzip bzip2 xz zstd p7zip unrar

# Minimal (most common formats)
sudo pacman -S wget tar unzip bzip2 xz
```

### macOS (Homebrew)
```bash
# Install all supported compression tools
brew install wget xz zstd p7zip unrar

# Most tools are pre-installed on macOS
```

## Usage Examples

### Example 1: Standard tar.gz Archive
```bash
# Download and extract a binary from a tar.gz
download "https://example.com/tool-v1.0-linux-amd64.tar.gz"
unpack "https://example.com/tool-v1.0-linux-amd64.tar.gz" 0 tool
mv "${bin}/tool" "${HOME}/.local/bin/"
```

### Example 2: Archive with Subdirectories
```bash
# Extract from archive with 1 level of subdirectories
# If archive structure is: package-name/bin/binary
unpack "${download_url}" 1 bin/binary
```

### Example 3: ZIP Archive
```bash
# ZIP files work the same way
download "https://example.com/tool.zip"
unpack "https://example.com/tool.zip" 0 tool.exe
```

### Example 4: Multiple Files
```bash
# Extract multiple files from one archive
unpack "${download_url}" 0 file1 file2 file3
```

### Example 5: Nested Archives (like rustscan)
```bash
# First unpack outer zip
unpack "outer.zip" 0 "inner.tar.gz"
mv "${bin}/inner.tar.gz" "${assets}/"

# Then unpack inner tar.gz
unpack "inner.tar.gz" 0 binary
```

## Format Detection

The script automatically detects formats based on file extensions:

```bash
# Function automatically called within unpack()
compression_type=$(detect_compression_type "${archive}")
```

Detection logic:
- Checks file extension patterns
- Returns standardized compression type
- Handles both long (`.tar.gz`) and short (`.tgz`) extensions
- Returns `"unknown"` for unsupported formats

## Error Handling

The script will:
1. **Detect missing tools**: Checks if required decompression tool is installed
2. **Log clear errors**: Provides specific error messages
3. **Return error codes**: Functions return 1 on failure, 0 on success
4. **Handle edge cases**: Missing files, already-unpacked files, etc.

Example error messages:
```
[!] tar is not installed
[-] Unknown archive format: file.unknown
[-] file.tar.gz does not exist; Was it successfully downloaded?
```

## Best Practices

### 1. Choose the Right Format
- **For speed**: Use `.tar.zst` or `.tar.gz`
- **For size**: Use `.tar.xz` or `.7z`
- **For compatibility**: Use `.tar.gz` or `.zip`

### 2. Consider Your Users
- `.tar.gz` is the safest choice (universal support)
- Provide multiple format options when possible
- Document required tools in your README

### 3. Testing
Always test extraction with:
```bash
# Verify the archive can be extracted
if ! unpack "${url}" 0 binary_name; then
    log error "Extraction failed"
    return 1
fi
```

### 4. Verify Extracted Files
```bash
# Check if binary exists and is executable
if [[ ! -x "${bin}/binary_name" ]]; then
    chmod +x "${bin}/binary_name"
fi
```

## Troubleshooting

### Problem: "tar is not installed"
**Solution:** Install tar package
```bash
sudo dnf install tar  # Fedora/RHEL
sudo apt install tar  # Debian/Ubuntu
```

### Problem: "Unknown archive format"
**Solution:** Check if the file extension is supported. If it's a new format, the script may need updating.

### Problem: "Failed to unarchive"
**Possible causes:**
1. Corrupted download
2. Missing required tool
3. Incorrect file paths in archive
4. Permission issues

**Solution:** Check the archive manually:
```bash
tar -tzf archive.tar.gz  # List contents
unzip -l archive.zip     # List contents
```

### Problem: Files extracted to wrong location
**Solution:** Check the `sublevel` parameter. Use `tar -tzf` to inspect archive structure first.

## Performance Tips

1. **Use zstd for modern systems**: Fastest decompression with good compression
2. **Pre-install tools**: Don't wait for errors; install all tools upfront
3. **Cache downloads**: The script already keeps files in `${assets}`
4. **Parallel operations**: Extract multiple independent archives simultaneously

## Format Recommendations by Use Case

| Use Case | Recommended Format | Reason |
|----------|-------------------|--------|
| GitHub Releases | `.tar.gz` | Universal compatibility |
| Large Software (>100MB) | `.tar.xz` or `.tar.zst` | Better compression |
| Cross-platform Tools | `.zip` | Works everywhere |
| Linux-only Tools | `.tar.zst` | Modern, fast, efficient |
| Archived Logs | `.gz` or `.xz` | Single file compression |
| Maximum Compression | `.tar.xz` or `.7z` | Best ratios |

## Conclusion

The enhanced `unpack()` function supports virtually all common compression formats used in software distribution. Choose the right format based on your needs for speed, size, and compatibility.