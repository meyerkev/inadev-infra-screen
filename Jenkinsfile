pipeline {
    agent any

    environment {
        HELM_VERSION = "3.10.1"  // Change to the desired Helm version
        CHART_NAME = "inadev-kmeyer"  // Change to your Helm chart name
        NAMESPACE = "inadev-kmeyer"  // Change to the Kubernetes namespace where you want to install the chart
        IMAGE_REPOSITORY = "386145735201.dkr.ecr.us-east-2.amazonaws.com/weather"  // Change to your Docker image repository
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker in docker') {
            steps {
                container('dind') {
                    script {
                        // Build the Docker image
                        sh "docker version || echo 'Docker not installed'"
                        sh "export GIT_TAG=\$(git rev-parse HEAD) && docker build -t ${IMAGE_REPOSITORY}:${GIT_TAG} src/app/ && docker push ${IMAGE_REPOSITORY}:${GIT_TAG}"
                    }
                }
            }
        }
            steps {
                script {
                    // Install the Helm chart
                    sh "export GIT_TAG=\$(git rev-parse HEAD) && helm upgrade --install ${CHART_NAME} ./helm/inadev-kmeyer --namespace=${NAMESPACE} --create-namespace --atomic --timeout=5m --wait --set image.repository=${IMAGE_REPOSITORY},image.tag=${GIT_TAG}"
                }
            }
        }
    }

    post {
        success {
            echo "Helm chart deployment successful!"
        }
        failure {
            echo "Helm chart deployment failed."
        }
    }
}