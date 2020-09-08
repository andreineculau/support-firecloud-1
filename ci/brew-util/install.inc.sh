#!/usr/bin/env bash
set -euo pipefail

# install erlang without wxmac bloat
function brew_install_one_erlang() {
    local FORMULA="$@"

    local FULLNAME=$(echo "${FORMULA}" | cut -d " " -f 1)
    local NAME=$(basename "${FULLNAME}" | sed "s/\.rb\$//")
    local OPTIONS=$(echo "${FORMULA} " | cut -d " " -f 2- | xargs -n 1 | sort -u)

    echo_do "brew: Installing ${NAME}, without wxmac..."
    brew tap linuxbrew/xorg
    # using a for loop because 'xargs -r' is not part of the BSD version (MacOS)
    # comm -23 <(brew deps ${NAME}) <(brew deps wxmac) | sed "/^wxmac$/d" | xargs -r -L1 brew install
    for DEP_NAME in $(comm -23 <(brew deps ${NAME}) <(brew deps wxmac) | sed "/^wxmac$/d"); do
        brew install ${DEP_NAME}
    done
    brew install --force --ignore-dependencies ${FULLNAME} ${OPTIONS} || \
        brew link --force --overwrite ${NAME}
    echo_done
}

function brew_install_one_core() {
    local FORMULA="$@"

    local FULLNAME=$(echo "${FORMULA}" | cut -d " " -f 1)
    local NAME=$(basename "${FULLNAME}" | sed "s/\.rb\$//")
    local OPTIONS=$(echo "${FORMULA} " | cut -d " " -f 2- | xargs -n 1 | sort -u)

    # is it already installed ?
    if brew list "${NAME}" >/dev/null 2>&1; then
        # is it a url/path to a formula.rb file
        [[ "${FULLNAME}" = "${FULLNAME%.rb}" ]] || {
            brew uninstall ${NAME}

            echo_do "brew: Installing ${FORMULA}..."
            if [[ "${CI:-}" != "true" ]]; then
                brew install ${FORMULA}
            else
                brew install --force ${FORMULA} || brew link --force --overwrite ${NAME}
            fi
            echo_done

            return 0
        }

        # install without specific options ?
        [[ -n "${OPTIONS}" ]] || {
            echo_skip "brew: Installing ${FORMULA}..."
            brew_upgrade ${NAME}
            return 0
        }

        # is it already installed with the required options ?
        local USED_OPTIONS="$(brew info --json=v1 ${NAME} | \
            /usr/bin/python \
                -c 'import sys,json;print "".join(json.load(sys.stdin)[0]["installed"][0]["used_options"])' | \
            xargs -n 1 | \
            sort -u || true)"
        local NOT_FOUND_OPTIONS="$(comm -23 <(echo "${OPTIONS}") <(echo "${USED_OPTIONS}"))"
        [[ -n "${NOT_FOUND_OPTIONS}" ]] || {
            echo_skip "brew: Installing ${FORMULA}..."
            brew_upgrade ${NAME}
            return 0
        }

        echo_err "${NAME} is already installed with options '${USED_OPTIONS}',"
        echo_err "but not the required '${NOT_FOUND_OPTIONS}'."

        if [[ "${TRAVIS:-}" = "true" ]]; then
            brew uninstall ${NAME}
        else
            echo_err "Consider uninstalling ${NAME} with 'brew uninstall ${NAME}' and rerun the bootstrap!"
            return 1
        fi
    fi

    echo_do "brew: Installing ${FORMULA}..."
    brew install ${FORMULA}
    echo_done
}

function brew_install_one() {
    local FORMULA="$@"

    local FULLNAME=$(echo "${FORMULA}" | cut -d " " -f 1)
    local NAME=$(basename "${FULLNAME}" | sed "s/\.rb\$//")
    # local OPTIONS=$(echo "${FORMULA} " | cut -d " " -f 2- | xargs -n 1 | sort -u)

    if [[ "$(type -t "brew_install_one_${NAME}")" = "function" ]]; then
        eval "brew_install_one_${NAME} '${FORMULA}'"
        return 0
    fi

    brew_install_one_core "${FORMULA}"
}

function brew_install() {
    while read -u3 FORMULA; do
        [[ -n "${FORMULA}" ]] || continue
        brew_install_one ${FORMULA}
    done 3< <(echo "$@")
    # see https://github.com/Homebrew/brew/issues/5013
    hash -r
}
