#!/bin/bash
set -eo pipefail

if [[ -f /var/run/docker.sock ]]; then
    chmod 777 /var/run/docker.sock
fi

exec "$@"