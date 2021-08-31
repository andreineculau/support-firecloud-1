#!/usr/bin/env bash
set -euo pipefail

after_script() {
    EXIT_STATUS=$?
    ./.ci.sh after_script
    exit ${EXIT_STATUS}
}
trap after_script EXIT

{
    ./.ci.sh before_install
    ./.ci.sh install
    ./.ci.sh before_script
    ./.ci.sh script
} && SF_CI_STATUS=success || SF_CI_STATUS=failure

if [[ "${SF_CI_STATUS}" = "success" ]]; then
    ./.ci.sh before_cache || true;
    ./.ci.sh after_success || true;
fi

if [[ "${SF_CI_STATUS}" = "failure" ]]; then
    ./.ci.sh after_failure || true;
    exit 1;
fi
