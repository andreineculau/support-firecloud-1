#!/usr/bin/env bash
set -euo pipefail

sf_transcrypt() {
    [ "${TRAVIS_EVENT_TYPE}" = "pull_request" ] || \
    [ ! -x "./.transcrypt" ] || \
    [ -z "${TRANSCRYPT_PASSWORD}" ] || \
    ./transcrypt -y -c aes-256-cbc -p "${TRANSCRYPT_PASSWORD}" && \
        unset TRANSCRYPT_PASSWORD
}

sf_os() {
    TRAVIS_NOSUDO_MARKER="-nosudo"
    [ "${TRAVIS_SUDO}" != "true" ] || TRAVIS_NOSUDO_MARKER=
    "./ci/${TRAVIS_OS_NAME}${TRAVIS_NOSUDO_MARKER}/bootstrap"
}

sf_travis_run_before_install() {
    sf_transcrypt
    sf_os
}

sf_travis_run_install() {
    make deps
}

sf_travis_run_script() {
    make
}

if [ "$(type -t "travis_run_${1}")" = "function" ]; then
    eval "travis_run_${1}"
elif [ "$(type -t "sf_travis_run_${1}")" = "function" ]; then
    eval "sf_travis_run_${1}"
fi
