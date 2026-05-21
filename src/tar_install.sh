#!/usr/bin/env bash

basedir="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
source "${basedir}/log.sh"
source "${basedir}/software_info.sh"

temp=$(mktemp -d)
assets="${temp}/assets"
bin="${temp}/bin"

# Cleanup on exit
trap 'rm -rf "${temp}"' EXIT

# Create directories if they don't exist
mkdir -p "${assets}" "${bin}"

function check_command() {
    # check_command <command_name>
    local cmd="${1}"
    if [[ -z "$(command -v "${cmd}")" ]]; then
        log warn "${cmd} is not installed"
        return 1
    fi
    return 0
}

function download() {
    # download <url>
    if ! check_command wget; then
        log warn "wget is not installed, install with 'sudo apt install wget' or 'sudo dnf install wget'"
        return 1
    fi

    local url="${1}"
    local filename
    filename="$(basename "${url}")"

    if [[ -z "${url}" ]]; then
        log error "No URL provided to download function"
        return 1
    fi

    if [[ -f "${assets}/${filename}" ]]; then
        log notice "${filename} already exists"
        return 0
    fi

    log info "Downloading ${filename} from ${url} to ${assets}"

    if wget -P "${assets}" -q "${url}" 2>&1; then
        log info "Successfully downloaded ${filename}"
        return 0
    else
        log error "Downloading ${filename} failed"
        return 1
    fi
}

function detect_compression_type() {
    # detect_compression_type <archive_path>
    local archive="${1}"

    case "${archive}" in
        *.tar.gz|*.tgz)
            echo "tar.gz"
            ;;
        *.tar.bz2|*.tbz2)
            echo "tar.bz2"
            ;;
        *.tar.xz|*.txz)
            echo "tar.xz"
            ;;
        *.tar.zst|*.tzst)
            echo "tar.zst"
            ;;
        *.tar)
            echo "tar"
            ;;
        *.zip)
            echo "zip"
            ;;
        *.gz)
            echo "gz"
            ;;
        *.bz2)
            echo "bz2"
            ;;
        *.xz)
            echo "xz"
            ;;
        *.zst)
            echo "zst"
            ;;
        *.7z)
            echo "7z"
            ;;
        *.rar)
            echo "rar"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

function unpack() {
    # unpack <download_url> <sublevel> <files...>
    local archive="${assets}/$(basename "${1}")"
    local sublevel="${2}"
    shift 2
    local files=("${@}")
    local rc=0
    local compression_type

    if [[ ! -f "${archive}" ]]; then
        log error "${archive} does not exist; Was it successfully downloaded?"
        return 1
    fi

    # Check if any of the target files already exist
    local all_exist=true
    for file in "${files[@]}"; do
        if [[ ! -f "${bin}/${file}" ]]; then
            all_exist=false
            break
        fi
    done

    if [[ "${all_exist}" == "true" ]]; then
        log notice "All files have already been unpacked"
        return 0
    fi

    compression_type=$(detect_compression_type "${archive}")

    case "${compression_type}" in
        tar.gz)
            if ! check_command tar; then
                log error "tar is not installed"
                return 1
            fi
            tar --strip-components="${sublevel}" -xzf "${archive}" -C "${bin}" "${files[@]}" --warning=no-unknown-keyword 2>/dev/null
            rc="${?}"
            ;;
        tar.bz2)
            if ! check_command tar; then
                log error "tar is not installed"
                return 1
            fi
            tar --strip-components="${sublevel}" -xjf "${archive}" -C "${bin}" "${files[@]}" --warning=no-unknown-keyword 2>/dev/null
            rc="${?}"
            ;;
        tar.xz)
            if ! check_command tar; then
                log error "tar is not installed"
                return 1
            fi
            tar --strip-components="${sublevel}" -xJf "${archive}" -C "${bin}" "${files[@]}" --warning=no-unknown-keyword 2>/dev/null
            rc="${?}"
            ;;
        tar.zst)
            if ! check_command tar || ! check_command zstd; then
                log error "tar or zstd is not installed"
                return 1
            fi
            tar --strip-components="${sublevel}" --use-compress-program=zstd -xf "${archive}" -C "${bin}" "${files[@]}" --warning=no-unknown-keyword 2>/dev/null
            rc="${?}"
            ;;
        tar)
            if ! check_command tar; then
                log error "tar is not installed"
                return 1
            fi
            tar --strip-components="${sublevel}" -xf "${archive}" -C "${bin}" "${files[@]}" --warning=no-unknown-keyword 2>/dev/null
            rc="${?}"
            ;;
        zip)
            if ! check_command unzip; then
                log error "unzip is not installed"
                return 1
            fi
            # unzip doesn't support --strip-components, so we handle it differently
            if [[ "${sublevel}" -gt 0 ]]; then
                local temp_extract="${bin}/temp_extract_$$"
                mkdir -p "${temp_extract}"
                unzip -o -q "${archive}" "${files[@]}" -d "${temp_extract}" 2>/dev/null
                rc="${?}"
                if [[ "${rc}" -eq 0 ]]; then
                    # Move files from sublevel directory to bin
                    find "${temp_extract}" -mindepth "${sublevel}" -maxdepth "${sublevel}" -exec mv {} "${bin}/" \; 2>/dev/null
                fi
                rm -rf "${temp_extract}"
            else
                unzip -o -q "${archive}" "${files[@]}" -d "${bin}" 2>/dev/null
                rc="${?}"
            fi
            ;;
        gz)
            if ! check_command gunzip; then
                log error "gunzip is not installed"
                return 1
            fi
            gunzip -c "${archive}" > "${bin}/${files[0]}"
            rc="${?}"
            ;;
        bz2)
            if ! check_command bunzip2; then
                log error "bunzip2 is not installed"
                return 1
            fi
            bunzip2 -c "${archive}" > "${bin}/${files[0]}"
            rc="${?}"
            ;;
        xz)
            if ! check_command unxz; then
                log error "unxz is not installed"
                return 1
            fi
            unxz -c "${archive}" > "${bin}/${files[0]}"
            rc="${?}"
            ;;
        zst)
            if ! check_command unzstd; then
                log error "unzstd is not installed"
                return 1
            fi
            unzstd -c "${archive}" > "${bin}/${files[0]}"
            rc="${?}"
            ;;
        7z)
            if ! check_command 7z; then
                log error "7z is not installed"
                return 1
            fi
            7z x "${archive}" -o"${bin}" "${files[@]}" -y >/dev/null 2>&1
            rc="${?}"
            ;;
        rar)
            if ! check_command unrar; then
                log error "unrar is not installed"
                return 1
            fi
            unrar x "${archive}" "${bin}/" "${files[@]}" -y >/dev/null 2>&1
            rc="${?}"
            ;;
        *)
            log error "Unknown archive format: ${archive}"
            return 1
            ;;
    esac

    if [[ "${rc}" -gt 0 ]]; then
        log warn "Failed to unarchive ${archive}"
        return 1
    else
        log info "Successfully unpacked ${files[*]} from ${archive}"
        return 0
    fi
}

function yaak_install() {
    if ! download "${yaak_download_url}"; then
        log error "Failed to download yaak"
        return 1
    fi
    sudo dnf install -y "${assets}/yaak-${yaak_version}-1.${hardware}.rpm"
}

function golangci_lint_install() {
    if ! download "${golangci_lint_download_url}"; then
        log error "Failed to download golangci-lint"
        return 1
    fi
    sudo dnf install -y "${assets}/golangci-lint-${golangci_lint_version}-${os,,}-${hardware_map[${hardware}]}.rpm"
}

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

function go_migrate_install() {
    if ! download "${go_migrate_download_url}"; then
        log error "Failed to download go-migrate"
        return 1
    fi

    if ! unpack "${go_migrate_download_url}" 0 migrate; then
        log error "Failed to unpack go-migrate"
        return 1
    fi

    mkdir -p "${HOME}/.local/bin"
    mv "${bin}/migrate" "${HOME}/.local/bin/go-migrate"
    chmod +x "${HOME}/.local/bin/go-migrate"
    log info "go-migrate installed to ${HOME}/.local/bin/go-migrate"
}

function rustscan_install() {
    local tararchive="x86_64-linux-rustscan.tar.gz"

    if ! download "${rustscan_download_url}"; then
        log error "Failed to download rustscan"
        return 1
    fi

    # First unpack the zip to get the tar.gz
    if ! unpack "${rustscan_download_url}" 0 "${tararchive}"; then
        log error "Failed to unpack rustscan zip"
        return 1
    fi

    # Move the tar.gz to assets and unpack it
    mv "${bin}/${tararchive}" "${assets}/"

    if ! unpack "${tararchive}" 0 rustscan; then
        log error "Failed to unpack rustscan tar.gz"
        return 1
    fi

    mkdir -p "${HOME}/.local/bin"
    mv "${bin}/rustscan" "${HOME}/.local/bin/"
    chmod +x "${HOME}/.local/bin/rustscan"
    log info "rustscan installed to ${HOME}/.local/bin/rustscan"
}

# Main script logic
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    if [[ $# -eq 0 ]]; then
        log error "No installation function specified"
        log info "Available functions: yaak_install, golangci_lint_install, sqlc_install, go_migrate_install, rustscan_install"
        exit 1
    fi

    # Execute the specified function
    if declare -f "${1}" > /dev/null; then
        "${@}"
    else
        log error "Unknown function: ${1}"
        exit 1
    fi
fi
