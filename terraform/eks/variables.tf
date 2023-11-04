variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_name" {
  type    = string
  default = "inadev-kmeyer"
}

variable "vpc_name" {
  type    = string
  default = null
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "create_key_pair" {
  type    = bool
  default = true
}

variable "key_pair_name" {
  type    = string
  default = null
}

variable "key_pair_name_prefix" {
  type    = string
  default = "inadev-kmeyer"
}