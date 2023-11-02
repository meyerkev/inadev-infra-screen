#!/bin/bash
set -eo pipefail

if [[ -f ".env" ]]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
fi

if [[ -z "${OPENWEATHERMAP_API_KEY}" ]]; then
    OPENWEATHERMAP_API_KEY=placeholder-build-value
fi

set -u


# Make your image
docker build --build-arg OPENWEATHERMAP_API_KEY=$OPENWEATHERMAP_API_KEY -t weather-app -f src/DOCKERFILE src

# Push all tehhe terraform
# TODO: Break the ECR repo creation into a separate tf module
terraform apply -auto-approve

# Something like 386145735201.dkr.ecr.us-east-2.amazonaws.com/weather
# Luckily for us, docker login works without having to strip the full path
ECR_REPOSITORY=$(terraform output -json | jq -r .weather_repository_url.value)
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ECR_REPOSITORY}

docker tag weather-app:latest $ECR_REPOSITORY
docker push $ECR_REPOSITORY
