output "weather_repository_url" {
  value = try(aws_ecr_repository.weather.repository_url, null)
}

output "update_kubeconfig" {
  value = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}