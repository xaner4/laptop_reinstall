#!/usr/bin/env bash

basedir="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
source "${basedir}/log.sh"

dnf_pkg=(
    jq
    yq
    tmux
    git
    htop
    curl
    wget
    tldr
    ripgrep
    wireguard-tools
    sqlitebrowser
    shellcheck
    tlp
    bat
    discord
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
    gcc
    make
)

uv_pkg=(
    ansible
)

gh_pkg=(
    yaak
    golangci_lint
)

os="$(uname)"
hardware=$(uname -m)
declare -A hardware_map
hardware_map["x86_64"]="amd64"
hardware_map["arm64"]="arm64"

export yaak_version="2026.2.0"
export yaak_version_page="mountain-loop/yaak"
export yaak_download_url="https://github.com/${yaak_version_page}/releases/download/v${yaak_version}/yaak-${yaak_version}-1.${hardware}.rpm"

export golangci_lint_version="2.9.0"
export golangci_lint_version_page="golangci/golangci-lint"
export golangci_lint_download_url="https://github.com/${golangci_lint_version_page}/releases/download/v${golangci_lint_version}/golangci-lint-${golangci_lint_version}-${os,,}-${hardware_map[${hardware}]}.rpm"

function update_version_tags() {
    args=("${@}")
    for pkg in "${args[@]}"; do
        log info "Updateing GH version number for ${pkg}"
        github_release_tag "${pkg}"
    done
}

function github_release_tag() {
    software_name="${1}"
    version_var="${software_name}_version"
    current_version="${!version_var}"
    repo_var="${software_name}_version_page"
    org_repo="${!repo_var}"
    latest=$(curl -sL https://api.github.com/repos/${org_repo}/releases/latest | grep tag_name | awk -F'"' '{gsub(/^v/, "", $4); print $4}')
    rc=${?}
    if [[ "${rc}" -gt 0 || "${latest}" == "null" || "${latest}" == "" ]];then
        log error "Could not fetch Github version from ${org_repo}"
        return
    fi

    if [ "${current_version}" == "${latest}" ]; then
        log info "${software_name} is already latest"
        return
    fi

    update_version "${software_name}" "${latest}"
}

function update_version() {
    software_name="${1}"
    version_var="${software_name}_version"
    current_version="${!version_var}"
    latest="${2}"

    rc=0
    if [[ "$(uname)" == "Linux" ]]; then
        sed -i "s|${software_name}_version=\"${current_version}\"|${software_name}_version=\"${latest}\"|g" "${basedir}/software_info.sh"
        rc="${?}"
    elif [[ "$(uname)" == "Darwin" ]]; then
        # macOS (BSD sed) requires an explicit backup suffix; use empty string ''
        sed -i '' "s|${software_name}_version=\"${current_version}\"|${software_name}_version=\"${latest}\"|g" "${basedir}/software_info.sh"
        rc="${?}"
    fi

    if [[ "${rc}" -gt 0 ]]; then
        log error "Something went wrong updating version for ${software_name}"
        return
    fi
    log notice "${software_name} has been update to version ${latest} from ${current_version}"
}
