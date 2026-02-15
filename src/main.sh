#!/usr/bin/env bash

basedir="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
source "${basedir}/log.sh"
source "${basedir}/dnf.sh"
source "${basedir}/pip.sh"
source "${basedir}/curl2sh.sh"
source "${basedir}/software_info.sh"
source "${basedir}/tar_install.sh"

function main() {
    dnf_config
    dnf_rpmfusion
    dnf_dockerrepo
    dnf_update
    dnf_install "${dnf_pkg[@]}"

    curl_install https://astral.sh/uv/install.sh
    uv_install "${uv_pkg[@]}"

    curl_install https://raw.githubusercontent.com/xaner4/go-update/refs/heads/main/go-update.sh
    if [[ -z "$(command -v zed)" ]]; then
        curl_install https://zed.dev/install.sh
    fi

    update_version_tags "${gh_pkg[@]}"
    yaak_install
    golangci_lint_install
    sqlc_install
}

main
