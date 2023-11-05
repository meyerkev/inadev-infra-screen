variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "ecr_repository_names" {
  type    = list(string)
  default = ["weather", "jenkins"]
}

variable "force_delete_ecr_repositories" {
  type    = bool
  default = false
}