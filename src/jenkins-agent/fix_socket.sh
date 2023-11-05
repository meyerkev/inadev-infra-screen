#!/bin/bash
set -ou pipefail

echo "Entering entrypoint"

if [[ -e /var/run/docker.sock ]]; then
    ls -la /var/run/docker.sock
    chmod 777 /var/run/docker.sock
    ls -la /var/run/docker.sock
else
    echo "No docker socket found"
fi

echo $@

su - jenkins "$@"