#!/bin/bash
set -eo pipefail


if [[ -f ".env" ]]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
fi

if [[ -z "${OPENWEATHERMAP_API_KEY}" ]]; then
    if [[ -z $1 ]]; then
        echo "OPENWEATHERMAP_API_KEY is not set"
        echo "Usage: $0 <OPENWEATHERMAP_API_KEY>"
        exit 1
    else
        export OPENWEATHERMAP_API_KEY=$1
    fi
fi

set -u

docker build --build-arg OPENWEATHERMAP_API_KEY=$OPENWEATHERMAP_API_KEY -t weather-app -f src/DOCKERFILE src
docker run -p 5000:5000 weather-app
