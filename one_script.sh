#!/bin/bash
set -eo pipefail

if [[ -f ".env" ]]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
fi

if [[ -z "${OPENWEATHERMAP_API_KEY}" ]]; then
    OPENWEATHERMAP_API_KEY=placeholder-build-value
fi

if [[ -z ${GITHUB_AUTH_TOKEN} ]]; then 
    echo "GITHUB_AUTH_TOKEN is required"
    exit 1
fi

if [[ -z ${GITHUB_REPOSITORY_URL} ]]; then 
    GITHUB_REPOSITORY_URL=https://github.com/meyerkev/inadev-infra-screen.git
fi

set -u

cd $(dirname $0)

# Make your image first so if it breaks, you're not waiting for the 45 minute long EKS cluster to build (... or fail to build)
docker build --build-arg OPENWEATHERMAP_API_KEY=$OPENWEATHERMAP_API_KEY -t weather-app -f src/app/DOCKERFILE src/app

# Push all the terraform
# TODO: Break the ECR repo creation into a separate tf module
terraform apply -auto-approve

# Something like 386145735201.dkr.ecr.us-east-2.amazonaws.com/weather
# Luckily for us, docker login works without having to strip the full path
ECR_REPOSITORY=$(terraform output -json | jq -r .weather_repository_url.value)
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ECR_REPOSITORY}

docker tag weather-app:latest $ECR_REPOSITORY
docker push $ECR_REPOSITORY

# aws eks --region us-east-2 update-kubeconfig --name inadev-kmeyer
`terraform output -raw update_kubeconfig`

# And now we can start talking to Jenkins
# Ideally, you would actually know all of these things walking into this instead of borrowing the default values
# but limits of a job interview
JENKINS_ENDPOINT=$(terraform output -raw jenkins_endpoint)
JENKINS_USERNAME=$(terraform output -raw jenkins_username)
JENKINS_PASSWORD=$(terraform output -raw jenkins_password)

docker build -t jenkins-setup -f src/jenkins-setup/DOCKERFILE src/jenkins-setup
docker run -e JENKINS_ENDPOINT="$JENKINS_ENDPOINT" -e JENKINS_USERNAME="$JENKINS_USERNAME" -e JENKINS_PASSWORD="$JENKINS_PASSWORD" -e GITHUB_AUTH_TOKEN="$GITHUB_AUTH_TOKEN" -e GITHUB_REPOSITORY_URL="$GITHUB_REPOSITORY_URL" jenkins-setup

echo "Jenkins is up at $JENKINS_ENDPOINT"
echo "We need to deploy the app to the cluster, but I'm not sure how to do that yet"
echo "Image is at $APP_IMAGE"
echo docker run -e JENKINS_ENDPOINT="$JENKINS_ENDPOINT" -e JENKINS_USERNAME="$JENKINS_USERNAME" -e JENKINS_PASSWORD="$JENKINS_PASSWORD" -e GITHUB_AUTH_TOKEN="$GITHUB_AUTH_TOKEN" -e GITHUB_REPOSITORY_URL="$GITHUB_REPOSITORY_URL" -it jenkins-setup bash
# Does it make sense to kill this?  
# docker image rm jenkins-setup


