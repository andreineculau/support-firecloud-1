#!/usr/bin/env bash
set -euo pipefail

SF_CI_IS_PR=false
# codeship set CI_PR_NUMBER=0 for non-PR executions...
[[ -z "${CI_PR_NUMBER:-}" ]] || [[ "${CI_PR_NUMBER:-}" = "0" ]] || SF_CI_IS_PR=true
[[ -z "${CI_PULL_REQUEST:-}" ]] || [[ "${CI_PR_NUMBER:-}" = "0" ]] || SF_CI_IS_PR=true

# in PRs, only run ux-minimal
if [[ "${SF_CI_IS_PR}" = "true" ]]; then
    [[ "${SF_CI_STEP_NAME}" = "ux-minimal" ]] || exit 0
fi

source ci/pipeline.script.sh

# deploy only version tags
GIT_TAG=$(git tag -l --points-at HEAD | head -1)
if [[ -n "${GIT_TAG}" ]]; then
    echo "${GIT_TAG}" | grep -q "^v[0-9]\+\.[0-9]\+\.[0-9]\+$" || exit 0
fi

source ci/pipeline.deploy.sh
