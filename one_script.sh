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

DOCKER_TAG=$(date +%s)

set -u

cd $(dirname $0)

# Make your image first so if it breaks, you're not waiting for the 45 minute long EKS cluster to build (... or fail to build)
docker build --build-arg OPENWEATHERMAP_API_KEY=$OPENWEATHERMAP_API_KEY -t weather -f src/app/Dockerfile src/app
docker build -t custom-jenkins -f src/jenkins-image/Dockerfile src/jenkins-image

# Make the ECR repos
pushd terraform/ecr
terraform init
terraform apply -auto-approve

# Build the app image
APP_IMAGE=$(terraform output -json | jq -r .repository_url.value.weather)
APP_TAG=${APP_IMAGE}:${DOCKER_TAG}
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${APP_IMAGE}
docker tag weather-app $APP_TAG
docker push $APP_TAG

# Build the Jenkins image
JENKINS_IMAGE=$(terraform output -json | jq -r .repository_url.value.jenkins)
JENKINS_TAG=${JENKINS_IMAGE}:${DOCKER_TAG}
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${JENKINS_IMAGE}
docker tag custom-jenkins $JENKINS_TAG
docker push $JENKINS_TAG

popd

# Push all the terraform
# TODO: Break the ECR repo creation into a separate tf module

pushd terraform/eks
terraform init
terraform apply -auto-approve -var "jenkins_image=${JENKINS_IMAGE}" -var "jenkins_tag=${DOCKER_TAG}" -var-file=tfvars/inadev.tfvars

# aws eks --region us-east-2 update-kubeconfig --name inadev-kmeyer
KUBECONFIG_COMMAND=`terraform output -raw update_kubeconfig`
$KUBECONFIG_COMMAND

# And now we can start talking to Jenkins
# Ideally, you would actually know all of these things walking into this instead of borrowing the default values
# but limits of a job interview
JENKINS_ENDPOINT=$(terraform output -raw jenkins_endpoint)
# /login is important, because otherwise it 403's
while [[ $(curl -s -o /dev/null -w "%{http_code}" $JENKINS_ENDPOINT/login) != "200" ]]; do
    echo "Waiting for Jenkins to come up"
    sleep 5
done

JENKINS_USERNAME=$(terraform output -raw jenkins_username)
JENKINS_PASSWORD=$(terraform output -raw jenkins_password)

popd

docker build -t jenkins-setup -f src/jenkins-setup/Dockerfile src/jenkins-setup
set +e
docker run -e JENKINS_ENDPOINT="$JENKINS_ENDPOINT" -e JENKINS_USERNAME="$JENKINS_USERNAME" -e JENKINS_PASSWORD="$JENKINS_PASSWORD" -e GITHUB_AUTH_TOKEN="$GITHUB_AUTH_TOKEN" -e GITHUB_REPOSITORY_URL="$GITHUB_REPOSITORY_URL" -e APP_IMAGE="$APP_IMAGE" jenkins-setup

echo "Jenkins is up at $JENKINS_ENDPOINT"
echo "Image is at $APP_IMAGE"
echo docker run -e JENKINS_ENDPOINT="$JENKINS_ENDPOINT" -e JENKINS_USERNAME="$JENKINS_USERNAME" -e JENKINS_PASSWORD="$JENKINS_PASSWORD" -e GITHUB_AUTH_TOKEN="$GITHUB_AUTH_TOKEN" -e GITHUB_REPOSITORY_URL="$GITHUB_REPOSITORY_URL" -e APP_IMAGE="$APP_IMAGE" -it jenkins-setup bash
# Q: Does it make sense to kill the setup container?
# A: Not while debugging, it doesn't.
# docker image rm jenkins-setup


