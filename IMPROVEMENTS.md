# Improvements to tar_install.sh

## Overview
This document outlines all the improvements made to the `tar_install.sh` script, including bug fixes, enhanced functionality, and better error handling.

## Key Improvements

### 1. **Enhanced `unpack()` Function - Multi-Format Support**

The `unpack()` function now supports a comprehensive range of compression formats:

#### Supported Formats:
- **tar.gz / .tgz** - Gzip compressed tarballs
- **tar.bz2 / .tbz2** - Bzip2 compressed tarballs
- **tar.xz / .txz** - XZ compressed tarballs
- **tar.zst / .tzst** - Zstandard compressed tarballs
- **tar** - Uncompressed tarballs
- **zip** - ZIP archives
- **gz** - Gzip compressed files
- **bz2** - Bzip2 compressed files
- **xz** - XZ compressed files
- **zst** - Zstandard compressed files
- **7z** - 7-Zip archives
- **rar** - RAR archives

#### New `detect_compression_type()` Function:
- Automatically detects compression format based on file extension
- Returns standardized compression type string
- Handles multiple extension variants (e.g., .tar.gz, .tgz)

### 2. **Bug Fixes**

#### Fixed Directory Creation Check
**Before:**
```bash
if [[ ! -f "${assets}" ]]; then
    mkdir -pv "${assets}"
fi
```

**After:**
```bash
mkdir -p "${assets}" "${bin}"
```

**Issue:** Used `-f` (file test) instead of `-d` (directory test), which would always fail. Now uses `mkdir -p` which creates directories if they don't exist and succeeds silently if they do.

#### Fixed Missing Quotes
**Before:**
```bash
basedir="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
filename="$(basename ${url})"
```

**After:**
```bash
basedir="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
filename="$(basename "${url}")"
```

**Issue:** Missing quotes could cause issues with paths containing spaces.

#### Fixed Array Handling in `unpack()`
**Before:**
```bash
files="${@:3}"
tar ... -C "${bin}" "${files}"
```

**After:**
```bash
shift 2
local files=("${@}")
tar ... -C "${bin}" "${files[@]}"
```

**Issue:** Proper array handling ensures multiple files are passed correctly as separate arguments.

#### Fixed Typos
- "exsist" → "exist"
- "know" → "known"
- "Notice" → "notice" (consistent casing)
- "packed out" → "unpacked" (better terminology)

### 3. **Improved Error Handling**

#### New `check_command()` Function
```bash
function check_command() {
    local cmd="${1}"
    if [[ -z "$(command -v "${cmd}")" ]]; then
        log warn "${cmd} is not installed"
        return 1
    fi
    return 0
}
```

**Benefits:**
- Centralized command availability checking
- Returns proper exit codes for error handling
- Used before attempting extraction operations

#### Proper Return Codes
All functions now return appropriate exit codes:
- `0` for success
- `1` for failure

This enables proper error checking:
```bash
if ! download "${url}"; then
    log error "Failed to download"
    return 1
fi
```

#### Enhanced `download()` Function
- Checks for wget availability before attempting download
- Returns proper exit codes
- Validates URL is provided
- Better error messages

### 4. **Resource Management**

#### Automatic Cleanup
```bash
trap 'rm -rf "${temp}"' EXIT
```

**Benefits:**
- Automatically removes temporary directory on script exit
- Works even if script fails or is interrupted
- Prevents temporary file accumulation

### 5. **Installation Function Improvements**

Each installation function now:
- Checks if download succeeded before unpacking
- Checks if unpacking succeeded before moving files
- Creates target directory if it doesn't exist (`mkdir -p "${HOME}/.local/bin"`)
- Sets executable permissions (`chmod +x`)
- Provides clear success messages
- Returns proper exit codes

**Example:**
```bash
function sqlc_install() {
    if ! download "${sqlc_download_url}"; then
        log error "Failed to download sqlc"
        return 1
    fi

    if ! unpack "${sqlc_download_url}" 0 sqlc; then
        log error "Failed to unpack sqlc"
        return 1
    fi

    mkdir -p "${HOME}/.local/bin"
    mv "${bin}/sqlc" "${HOME}/.local/bin/"
    chmod +x "${HOME}/.local/bin/sqlc"
    log info "sqlc installed to ${HOME}/.local/bin/sqlc"
}
```

### 6. **Code Quality Improvements**

#### Use of `local` Variables
All function variables are now declared as `local` to prevent namespace pollution:
```bash
function download() {
    local url="${1}"
    local filename
    filename="$(basename "${url}")"
    # ...
}
```

#### Consistent Quoting
All variable expansions are properly quoted to handle edge cases.

#### Reduced Verbosity
- Removed `-v` flag from `mkdir` (less noise)
- Redirected stderr to `/dev/null` for cleaner output when appropriate
- Added `-q` flag to unzip for quiet operation

### 7. **Enhanced ZIP Handling**

The unzip implementation now properly handles the `sublevel` parameter:

```bash
if [[ "${sublevel}" -gt 0 ]]; then
    local temp_extract="${bin}/temp_extract_$$"
    mkdir -p "${temp_extract}"
    unzip -o -q "${archive}" "${files[@]}" -d "${temp_extract}" 2>/dev/null
    rc="${?}"
    if [[ "${rc}" -eq 0 ]]; then
        find "${temp_extract}" -mindepth "${sublevel}" -maxdepth "${sublevel}" -exec mv {} "${bin}/" \; 2>/dev/null
    fi
    rm -rf "${temp_extract}"
else
    unzip -o -q "${archive}" "${files[@]}" -d "${bin}" 2>/dev/null
    rc="${?}"
fi
```

**Note:** `unzip` doesn't support `--strip-components` like `tar`, so this implements equivalent functionality.

### 8. **Script Execution Mode**

Added logic to allow the script to be sourced or executed directly:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    if [[ $# -eq 0 ]]; then
        log error "No installation function specified"
        log info "Available functions: yaak_install, golangci_lint_install, sqlc_install, go_migrate_install, rustscan_install"
        exit 1
    fi

    if declare -f "${1}" > /dev/null; then
        "${@}"
    else
        log error "Unknown function: ${1}"
        exit 1
    fi
fi
```

**Usage:**
```bash
# Source the script and call functions
source tar_install.sh
sqlc_install

# Or execute directly
./tar_install.sh sqlc_install
```

## Usage Examples

### Basic Installation
```bash
./tar_install.sh sqlc_install
```

### Installing Multiple Packages
```bash
for pkg in sqlc_install go_migrate_install rustscan_install; do
    ./tar_install.sh "$pkg"
done
```

### Sourcing and Using Functions
```bash
source tar_install.sh
sqlc_install
go_migrate_install
```

## Required Dependencies

### Core Tools (always needed):
- `wget` - For downloading files
- `tar` - For most archive formats

### Optional Tools (needed for specific formats):
- `unzip` - For .zip files
- `bunzip2` - For .bz2 files
- `unxz` or `xz` - For .xz files
- `zstd` - For .zst files
- `7z` (p7zip-full) - For .7z files
- `unrar` - For .rar files

### Installing Dependencies on Fedora/RHEL:
```bash
sudo dnf install wget tar unzip bzip2 xz zstd p7zip p7zip-plugins unrar
```

### Installing Dependencies on Debian/Ubuntu:
```bash
sudo apt install wget tar unzip bzip2 xz-utils zstd p7zip-full unrar
```

## Testing Recommendations

1. **Test with different compression formats:**
   ```bash
   # Create test archives
   tar -czf test.tar.gz file.txt
   tar -cjf test.tar.bz2 file.txt
   tar -cJf test.tar.xz file.txt
   zip test.zip file.txt
   ```

2. **Test error conditions:**
   - Missing archive file
   - Unsupported format
   - Missing required tools
   - Invalid URLs

3. **Test with spaces in filenames:**
   ```bash
   touch "file with spaces.txt"
   tar -czf "archive with spaces.tar.gz" "file with spaces.txt"
   ```

## Performance Considerations

- The `detect_compression_type()` function uses pattern matching, which is very fast
- Error output is redirected to `/dev/null` where appropriate to reduce noise
- The trap ensures cleanup happens efficiently on any exit condition

## Future Enhancements

Potential improvements for future versions:

1. **Progress indication** for large downloads (wget progress bar)
2. **Checksum verification** (SHA256/MD5) for downloaded files
3. **Parallel downloads** for multiple packages
4. **Retry logic** for failed downloads
5. **Cache management** - option to keep or clear downloaded files
6. **Version checking** before installation
7. **Uninstall functions** for installed packages
8. **Support for more package managers** (brew, snap, flatpak)

## Breaking Changes

None. All changes are backward compatible. Existing scripts using this file will continue to work as before.

## Conclusion

These improvements make the script more robust, maintainable, and feature-rich while fixing several bugs that could have caused issues in edge cases. The enhanced compression format support makes it suitable for a wider variety of software installations.