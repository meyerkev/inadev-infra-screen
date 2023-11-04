variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_k8s_version" {
  type    = string
  default = "1.28"
}

variable "eks_node_instance_type" {
  type    = string
  default = null # "m6g.large"
}

variable "target_architecture" {
  type    = string
  default = null
}

variable "min_nodes" {
  type    = number
  default = 1
}

variable "max_nodes" {
  type    = number
  default = 10
}

variable "desired_nodes" {
  type    = number
  default = 3
}

variable "vpc_id" {
  type = string
}

variable "vpc_subnets" {
  type = list(string)
}

variable "eks_key_pair_name" {
  type    = string
  default = null
}