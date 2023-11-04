resource "aws_ecr_repository" "repository" {
    for_each = toset(var.ecr_repository_names)
    name     = each.key
}