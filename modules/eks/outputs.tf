output "cluster_name" {
  value = try(module.eks.cluster_name, null)
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "oidc_provider_arn" {
  value = try(module.eks.oidc_provider_arn, null)
}

output "cluster_certificate_authority_data" {
  value = try(module.eks.cluster_certificate_authority_data, null)
}

output "cluster_endpoint" {
  value = try(module.eks.cluster_endpoint, null)
}