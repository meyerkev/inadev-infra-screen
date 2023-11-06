resource "aws_ecr_repository" "repository" {
  for_each = toset(var.ecr_repository_names)
  name     = each.key
  # Mutable tags enable
  image_tag_mutability = "MUTABLE"

  force_delete = var.force_delete_ecr_repositories
}

resource "aws_ssm_parameter" "app_ecr_repository" {
  name  = "/inadev/app_ecr_repository"
  type  = "String"
  value = try(aws_ecr_repository.repository["weather"].arn, "")
}