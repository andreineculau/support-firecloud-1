#!/usr/bin/env bash
set -euo pipefail

echo_do "brew: Installing NodeJS packages..."
# NOTE node can be installed in such a way that
# - "npm i -g" executables are not available in PATH
# - "npm i -g" is missing the right permissions
# therefore we always install it via homebrew
# unless_exe_and_grep_q_then "node --version | head -1" "^v" brew_install_one node
brew_install_one node
exe_and_grep_q "node --version | head -1" "^v"

# allow npm upgrade to fail on WSL; fails with EACCESS
unless_exe_and_grep_q_then "npm --version | head -1" "^6\." \
    npm install --global --force npm@6 || ${SUPPORT_FIRECLOUD_DIR}/bin/is-wsl

unless_exe_and_grep_q_then "pnpm --version | head -1" "^json 5\." \
    npm install --global pnpm@5

unless_exe_and_grep_q_then "json --version | head -1" "^json 9\." \
    npm install --global json@9

unless_exe_and_grep_q_then "semver --help | head -1" "^SemVer 7\." \
    npm install --global semver@7
echo_done
