// Install Helm, then run the Helm chart
pipeline {
    agent any

    environment {
        HELM_VERSION = "3.10.1"  // Change to the desired Helm version
        CHART_NAME = "inadev-kmeyer"  // Change to your Helm chart name
        NAMESPACE = "inadev-kmeyer"  // Change to the Kubernetes namespace where you want to install the chart
    }

    stages {
        stage('Install Helm') {
            steps {
                script {
                    // Download and install Helm
                    sh "curl -sSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar xz"
                    sh "mv linux-amd64/helm /usr/local/bin/"
                    sh "helm version --client"
                }
            }
        }

        stage('Deploy Helm Chart') {
            steps {
                script {
                    // Install the Helm chart
                    sh "helm upgrade --install ${CHART_NAME} ./helm/inadev-kmeyer --namespace=${NAMESPACE} --create-namespace --atomic --timeout=5m --wait"
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