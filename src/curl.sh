#!/usr/bin/env bash

function curl_install() {
  url="${1:-}"
  if [[ -z "$url" ]]; then
    printf '%s\n' "missing url" >&2
    return 2
  fi

  if command -v curl >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -fsSL "$url" | bash -
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    wget --https-only --secure-protocol=TLSv1_2 -q -O - "$url" | bash -
    return $?
  fi

  printf '%s\n' "neither curl nor wget found" >&2
  return 3
}
