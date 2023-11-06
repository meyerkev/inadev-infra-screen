pipeline {
    agent any     

    environment {
        HELM_VERSION = "3.10.1"  // Change to the desired Helm version
        CHART_NAME = "inadev-kmeyer"  // Change to your Helm chart name
        NAMESPACE = "inadev-kmeyer"  // Change to the Kubernetes namespace where you want to install the chart
        IMAGE_REPOSITORY = "386145735201.dkr.ecr.us-east-2.amazonaws.com/weather"  // Change to your Docker image repository
        // TODO: Make this a credential in a programatic way if you have time to figure out how to crack AES-256-CBC
        OPENWEATHERMAP_API_KEY = "4f68537b89f1d45818b9ed8efc57fec0" // Change to your OpenWeatherMap API key
        aws_password = sh(returnStdout: true, script: "aws ecr get-login-password --region us-east-2").trim()
        git_tag = sh(returnStdout: true, script: "date +%s").trim()
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
                        sh "printenv"
                        sh "pwd && ls"
                        sh "docker version || echo 'Docker not installed'"
                        sh "docker login --username AWS --password ${aws_password} ${IMAGE_REPOSITORY}"
                        sh "docker build -t ${IMAGE_REPOSITORY}:${git_tag} src/app/"
                        sh "docker push ${IMAGE_REPOSITORY}:${git_tag}"
                    }
                }
            }
        }
        stage('Deploy Helm chart') {
            steps {
                script {
                    // Install the Helm chart
                    sh "helm upgrade --install ${CHART_NAME} ./helm/inadev-kmeyer --namespace=${NAMESPACE} --create-namespace --atomic --timeout=5m --wait --set openweathermapApiKey=${OPENWEATHERMAP_API_KEY},image.repository=${IMAGE_REPOSITORY},image.tag=${git_tag}"
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