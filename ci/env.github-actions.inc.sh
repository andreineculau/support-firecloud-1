#!/usr/bin/env bash
# shellcheck disable=SC2034
true

git config --global user.email "actions@github.com"
git config --global user.name "Github Actions CI"

CI_DEBUG_MODE=${CI_DEBUG_MODE:-}
# travis -> github actions
# builds -> workflow runs
# jobs   -> job runs
# NOTE allow it to fail e.g. github-get-job-id depends on jq, and jq might nobe available
CI_JOB_ID=$(${SUPPORT_FIRECLOUD_DIR}/bin/github-get-job-id || true)
CI_JOB_URL="https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}/checks?check_suite_id=FIXME"
CI_PR_SLUG=
if [[ "${GITHUB_EVENT_NAME}" = "pull_request" ]]; then
    CI_PR_NUMBER=$(${SUPPORT_FIRECLOUD_DIR}/bin/jq -r .github.event.number ${GITHUB_EVENT_PATH})
    CI_PR_SLUG=https://github.com/${GITHUB_REPOSITORY}/pull/${CI_PR_NUMBER}
    unset CI_PR_NUMBER
fi
CI_REPO_SLUG=${GITHUB_REPOSITORY}
CI_IS_PR=false
if [[ "${GITHUB_EVENT_NAME}" = "pull_request" ]]; then
    CI_IS_PR=true
fi
CI_IS_CRON=false
if [[ -z "${GITHUB_EVENT_NAME}" ]]; then
    CI_IS_CRON=true
fi
CI_TAG=
if [[ "${GITHUB_REF:-}" =~ "^refs/tags/" ]]; then
    CI_TAG=${GITHUB_REF#refs\/tags\/}
fi
export CI=true
export GH_TOKEN=${GH_TOKEN:-${GITHUB_TOKEN}}
