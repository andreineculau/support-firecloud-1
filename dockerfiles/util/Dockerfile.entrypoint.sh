#!/usr/bin/env bash

# Run all /Dockerfile.entrypoint.d/*.sh entrypoints based on filename order
# see https://www.camptocamp.com/en/news-events/flexible-docker-entrypoints-scripts
# see https://github.com/camptocamp/docker-git/blob/master/docker-entrypoint.sh

if [[ -d "/Dockerfile.entrypoint.d" ]] && [[ -n "$(ls -A /Dockerfile.entrypoint.d)" ]]; then
    # using run-parts from homebrew's debianutils because alpine/centos don't support --verbose and --regex
    /home/linuxbrew/.linuxbrew/bin/run-parts --verbose --regex "\.sh$" "/Dockerfile.entrypoint.d"
fi

exec "$@"
