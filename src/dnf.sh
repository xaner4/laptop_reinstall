#!/usr/bin/env bash

basedir="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
source "${basedir}/log.sh"

function dnf_config() {
    dnfcfg="/etc/dnf/dnf.conf"
    if [[ ! -f "${dnfcfg}" ]]; then
        return
    fi
    grep "max_parallel_downloads" "${dnfcfg}"
    rc="${?}"
    if [[ "${rc}" -eq 1 ]]; then
        echo "max_parallel_downloads=10" | sudo tee -a "${dnfcfg}"
    fi

    grep "fastestmirror" "${dnfcfg}"
    rc="${?}"
    if [[ "${rc}" -eq 1 ]]; then
        echo "fastestmirror=true" | sudo tee -a "${dnfcfg}"
    fi


}

function dnf_rpmfusion() {
    log notice "Adding free and non-free epel releases"
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

function dnf_dockerrepo() {
    sudo dnf config-manager \
        addrepo --from-repofile \
        https://download.docker.com/linux/fedora/docker-ce.repo
}

function dnf_update() {
    log info "Updateing system to latest"
    sudo dnf update --refresh -y
}

function dnf_install() {
    args=("${@}")
    for pkg in "${args[@]}"; do
        log info "Installing ${pkg} from dnf"
        sudo dnf install -y "${pkg}"
    done
}
