#!/usr/bin/env bash

# This script is a dummy script, just to test the functionality of sh/env.inc.sh:make.

[[ -n "${SF_MAKE_COMMAND:-}" ]] || {
    echo >&2 "[ERR ] Expected SF_MAKE_COMMAND to be defined. Maybe GNU Make is not available."
    exit 1;
}

${SF_MAKE_COMMAND} "$@"
