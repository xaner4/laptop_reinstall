#!/usr/bin/env bash

basedir="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
source "${basedir}/log.sh"
source "${basedir}/software_info.sh"

function download() {
    # download <url>
    if [[ -z "$(command -v wget)" ]];then
        log warn "wget is not installed, install with 'sudo apt install wget'"
        return
    fi

    url="${1}"
    path="${assets}"
    filename="$(basename ${url})"
    if [[ -f "${assets}/${filename}" ]]; then
        log Notice "${filename} does already exists"
        return
    fi
    log info "Downloading ${filename} from ${url} to ${path}"
    wget -P "${assets}" -q "$url" 2>&1
    rc="${?}"
    if [[ "${rc}" -gt 0 ]]; then
        log error "Downloading ${filename} failed"
        return
    fi
}

function unpack() {
    # unpack <download_url> <sublevel> <files...>
    archive="${assets}/$(basename $1)"
    sublevel="${2}"
    files="${@:3}"
    if [[ ! -f ${archive} ]]; then
        log error "${archive} does not exsist; Was it successfully downloaded?"
        return
    fi
    if [[ -f "${bin}/{${files}}" ]]; then
        log notice "${files} has already been packed out"
        return
    fi
    case "${archive}" in
        *.tar.gz|*.tgz)
            tar --strip-components="${sublevel}" -xzf "${archive}" -C "${bin}" "${files}" --warning=no-unknown-keyword
            rc="${?}"
        ;;
        *)
            log error "Not an know archive format"
            return
        ;;
    esac

    if [[ "${rc}" -gt 0 ]]; then
        log warn "Not possible to unarchive ${archive}"
        return
    else
        log info "${files} has been successfully packed out from ${archive}"
    fi
}

function yaak_install() {
    download "${yaak_download_url}"
    sudo dnf install -y "${assets}/yaak-${yaak_version}-1.${hardware}.rpm"
}

function golangci_lint_install() {
    download "${golangci_lint_download_url}"
    sudo dnf install -y "${assets}/golangci-lint-${golangci_lint_version}-${os,,}-${hardware_map[${hardware}]}.rpm"
}

function sqlc_install() {
    download "${sqlc_download_url}"
    unpack "${sqlc_download_url}" 0 sqlc
    mv "${bin}/sqlc" ~/.local/bin
}
