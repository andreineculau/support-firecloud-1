#!/usr/bin/env bash

function sf_ci_run_script() {
    sf_ci_debug
    # skip running 'make deps' again (part of 'sf_ci_run_install' already)
    # make all test
    make build check test
}
