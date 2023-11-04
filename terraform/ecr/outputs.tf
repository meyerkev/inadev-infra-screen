output "repository_url" {
    value = {for name,repository in aws_ecr_repository.repository : name => repository.repository_url}
}