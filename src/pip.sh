#!/usr/bin/env bash

basedir="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
source "${basedir}/log.sh"

function uv_install() {
    args=("${@}")
    for pkg in "${args[@]}"; do
        log info "Installing ${pkg} from uv"
        uv tool install "${pkg}"
    done
}
