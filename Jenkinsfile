pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                containers:
                - name: docker
                    image: docker:latest
                    command:
                    - cat
                    tty: true
                    volumeMounts:
                    - mountPath: /var/run/docker.sock
                    name: docker-sock
                volumes:
                - name: docker-sock
                    hostPath:
                    path: /var/run/docker.sock    
                '''
        }
    }

    environment {
        HELM_VERSION = "3.10.1"  // Change to the desired Helm version
        CHART_NAME = "inadev-kmeyer"  // Change to your Helm chart name
        NAMESPACE = "inadev-kmeyer"  // Change to the Kubernetes namespace where you want to install the chart
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker') {
            steps {
                script {
                    // Build the Docker image
                    sh "sleep 3600"
                    sh "docker version"
                }
            }
        }
        stage('Deploy Helm Chart') {
            steps {
                script {
                    // Install the Helm chart
                    sh "pwd && ls -la"
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