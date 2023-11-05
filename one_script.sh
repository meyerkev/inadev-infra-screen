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

# Setup the environment
DOCKER_TAG=$(date +%s)
GIT_BRANCH=$(git branch --show-current)

echo "Building terraform for the ECR repostiories and EKS cluster"
# Make the ECR repos
pushd terraform/ecr
terraform init
terraform apply -auto-approve

APP_REPOSITORY=$(terraform output -json | jq -r .repository_url.value.weather)
JENKINS_IMAGE=$(terraform output -json | jq -r .repository_url.value.jenkins)
popd

echo "Building the app and docker images"
# Build the app image
docker build --build-arg OPENWEATHERMAP_API_KEY=$OPENWEATHERMAP_API_KEY -t weather src/app
APP_TAG=${APP_REPOSITORY}:${DOCKER_TAG}
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${APP_REPOSITORY}
docker tag weather-app $APP_TAG
docker push $APP_TAG

# Build the Jenkins image
docker build -t custom-jenkins-agent src/jenkins-agent
JENKINS_TAG=${JENKINS_IMAGE}:${DOCKER_TAG}
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${JENKINS_IMAGE}
docker tag custom-jenkins-agent $JENKINS_TAG
docker push $JENKINS_TAG
echo "Done building the app and docker images"

# Push all the terraform
# TODO: Break the ECR repo creation into a separate tf module

pushd terraform/eks
terraform init
terraform apply -auto-approve -var-file=tfvars/inadev.tfvars -var "jenkins_agent_image=$JENKINS_IMAGE" -var "jenkins_agent_tag=$DOCKER_TAG" -var "openweathermap_api_key=$OPENWEATHERMAP_API_KEY"

# aws eks --region us-east-2 update-kubeconfig --name inadev-kmeyer
KUBECONFIG_COMMAND=`terraform output -raw update_kubeconfig`
$KUBECONFIG_COMMAND

echo "Done building terraform for the ECR repostiories and EKS cluster"
echo "To access the cluster, run the following command:"
echo "$KUBECONFIG_COMMAND"
# And now we can start talking to Jenkins
# Ideally, you would actually know all of these things walking into this instead of borrowing the default values
# but limits of a job interview

echo "Waiting for Jenkins to come up"
JENKINS_ENDPOINT=$(terraform output -raw jenkins_endpoint)
# /login is important, because otherwise it 403's
while [[ $(curl -s -o /dev/null -w "%{http_code}" $JENKINS_ENDPOINT/login) != "200" ]]; do
    echo "Waiting for Jenkins to come up"
    sleep 5
done

JENKINS_USERNAME=$(terraform output -raw jenkins_username)
JENKINS_PASSWORD=$(terraform output -raw jenkins_password)

popd

echo "Jenkins is up; Configuring Jenkins"



docker build -t jenkins-setup -f src/jenkins-setup/Dockerfile src/jenkins-setup

#TODO: Send in the branch as a variable so our job uses the latest code for the branch
docker run \
    -e JENKINS_ENDPOINT="$JENKINS_ENDPOINT" \
    -e JENKINS_USERNAME="$JENKINS_USERNAME" \
    -e JENKINS_PASSWORD="$JENKINS_PASSWORD" \
    -e GITHUB_AUTH_TOKEN="$GITHUB_AUTH_TOKEN" \
    -e GITHUB_REPOSITORY_URL="$GITHUB_REPOSITORY_URL" \
    -e APP_REPOSITORY="$APP_REPOSITORY" \
    -e GIT_BRANCH="$GIT_BRANCH" \
    -e OPENWEATHERMAP_API_KEY="$OPENWEATHERMAP_API_KEY" \
    jenkins-setup

echo docker run -e JENKINS_ENDPOINT="$JENKINS_ENDPOINT" -e JENKINS_USERNAME="$JENKINS_USERNAME" -e JENKINS_PASSWORD="$JENKINS_PASSWORD" -e GITHUB_AUTH_TOKEN="$GITHUB_AUTH_TOKEN" -e GITHUB_REPOSITORY_URL="$GITHUB_REPOSITORY_URL" -e APP_IMAGE="$APP_IMAGE" -it jenkins-setup bash
# Q: Does it make sense to kill the setup container?
# A: Not while debugging, it doesn't.   
# docker image rm jenkins-setup

echo "Jenkins has been configured and we have triggered a build."
echo "Waiting for the build to complete and the service to come up"

echo "Your image repository is at: $APP_REPOSITORY"
echo "Please update the Jenkinsfile to use the correct ECR repository"
echo
echo "Jenkins is up at $JENKINS_ENDPOINT"
echo "Username: $JENKINS_USERNAME"
echo "Password: $JENKINS_PASSWORD"

#Wait for the service to come up
set +e # Don't exit on error
while true; do
    if kubectl get svc --namespace inadev-kmeyer inadev-kmeyer --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}" 2>&1 >/dev/null; then
        break
    fi
    echo "Waiting for service to come up"
    sleep 5
done



export SERVICE_IP=$(kubectl get svc --namespace inadev-kmeyer inadev-kmeyer --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
count=0
while [[ $(curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_IP) != "200" ]]; do
    echo "Waiting for service to come up at $SERVICE_IP"
    sleep 5
    count=$((count+1))
    # If it takes more than 5 minutes, something is wrong
    if [[ $count -gt 60 ]]; then
        echo "Service failed to come up"
        break
    fi
done
echo "----------------------------------------------------------"
echo "To access the cluster, run the following command:"
echo "$KUBECONFIG_COMMAND"
echo
echo "Your image repository is at: $APP_REPOSITORY"
echo "Please update the Jenkinsfile to use the correct ECR repository"
echo
echo "Jenkins is up at $JENKINS_ENDPOINT"
echo "Username: $JENKINS_USERNAME"
echo "Password: $JENKINS_PASSWORD"
echo "Your service can be found at: http://$SERVICE_IP"

