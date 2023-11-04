output "update_kubeconfig" {
  value = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "jenkins_endpoint" {
  value = "http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname}"
}

output "jenkins_username" {
  value = nonsensitive(data.kubernetes_secret.jenkins.data["jenkins-admin-user"])
}

output "jenkins_password" {
  value = nonsensitive(data.kubernetes_secret.jenkins.data["jenkins-admin-password"])
}