#!/usr/bin/env bash

basedir="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)"
source "${basedir}/log.sh"

function curl_install() {
  url="${1:-}"
  if [[ -z "$url" ]]; then
    log error "missing url"
    return 2
  fi

  if [[ -n "$(command -v curl)" ]]; then
    curl --proto '=https' --tlsv1.2 -fsSL "$url" | bash -
    return $?
  fi

  if [[ -n "$(command -v wget)" ]]; then
    wget --https-only --secure-protocol=TLSv1_2 -q -O - "$url" | bash -
    return $?
  fi

  log warn "neither curl nor wget found"
  return 3
}
