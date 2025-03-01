#!/usr/bin/env bash
set -euo pipefail

function pacman_list_installed() {
    echo_do "pacman: Listing packages..."
    ${SF_SUDO:-} pacman -Q
    echo_done
}

function pacman_cache_prune() {
    echo_do "pacman: Pruning cache..."
    # ${SF_SUDO:-} pacman -Scc
    ${SF_SUDO:-} pacman -Sc
    ${SF_SUDO:-} rm -rf /var/cache/pacman/pkg/*
    echo_done
}

# FIXME this module hasn't been fully tested

function pacman_update() {
    echo_do "pacman: Updating..."
    ${SF_SUDO:-} pacman -Syy
    echo_done
}

function pacman_install_one() {
    local PKG="$*"

    local BREW_VSN=$(echo "${PKG}@" | cut -d"@" -f2)
    [[ -z "${BREW_VSN}" ]] || {
        echo_err "Passing a major version á la Homebrew is not yet implemented."
        exit 1
    }

    echo_do "pacman: Installing ${PKG}..."
    ${SF_SUDO:-} pacman -S --noconfirm ${PKG}
    echo_done
    hash -r # see https://github.com/Homebrew/brew/issues/5013
}

function pacman_install_one_unless() {
    local FORMULA="$1"
    shift
    local EXECUTABLE=$(echo "$1" | cut -d" " -f1)

    if exe_and_grep_q "$@"; then
        echo_skip "pacman: Installing ${FORMULA}..."
    else
        pacman_install_one "${FORMULA}"
        >&2 debug_exe "${EXECUTABLE}"
        exe_and_grep_q "$@"
    fi
}
