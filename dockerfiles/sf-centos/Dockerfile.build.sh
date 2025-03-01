#!/usr/bin/env bash
set -euo pipefail

SUPPORT_FIRECLOUD_DIR=/support-firecloud
source ${SUPPORT_FIRECLOUD_DIR}/dockerfiles/util/common.inc.sh

# DEPS
# keep in sync with bootstrap/linux/bootstrap-sudo-centos
[[ -f /support-firecloud.bootstrapped ]] || {
    XTRACE_STATE_DOCKERFILE_BUILD_SH="$(set +o | grep xtrace)"
    set -x
    yum_update

    yum_install_one ca-certificates
    yum_install_one gnupg

    yum_install_one git
    yum_install_one openssl
    yum_install_one passwd
    yum_install_one sudo
    yum_install_one which

    [[ "${SF_SUDO}" = "sf_nosudo_fallback" ]] || export SF_SUDO=sudo

    source ${SUPPORT_FIRECLOUD_DIR}/dockerfiles/util/gitconfig.inc.sh
    source ${SUPPORT_FIRECLOUD_DIR}/dockerfiles/util/user.inc.sh
    eval "${XTRACE_STATE_DOCKERFILE_BUILD_SH}"
    unset XTRACE_STATE_DOCKERFILE_BUILD_SH
}

source ${SUPPORT_FIRECLOUD_DIR}/dockerfiles/util/bootstrap.inc.sh
source ${SUPPORT_FIRECLOUD_DIR}/dockerfiles/util/clean.inc.sh
