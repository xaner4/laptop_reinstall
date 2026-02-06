#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RESET='\033[0m'

function log() {
    loglevel=$(echo "${1}" | tr '[:upper:]' '[:lower:]')
    msg=${2}
    case ${loglevel} in
        info)
            echo -e "${GREEN}[+] ${msg}${RESET}"
            ;;
        notice)
            echo -e "${BLUE}[*] ${msg}${RESET}"
            ;;
        warn)
            echo -e "${YELLOW}[!] ${msg}${RESET}"
            ;;
        error)
            echo -e "${RED}[-] ${msg}${RESET}"
            ;;
    esac
}
