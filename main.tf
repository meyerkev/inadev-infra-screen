locals {
  # This will not work for all instance types just for the record
  # There's a hack on it, but I forget what it is
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  validate_key_pair = var.create_key_pair || var.key_pair_name != null ? "Please provide a keypair or create one" : true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>5.1.2"

  name = var.vpc_name == null ? "${var.cluster_name}-eks-vpc" : var.vpc_name
  cidr = var.vpc_cidr

  azs = local.availability_zones

  # TODO: Some regions have more than 4 AZ's
  public_subnets   = [for i, az in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets  = [for i, az in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 4)]
  database_subnets = [for i, az in local.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 8)]

  enable_dns_hostnames = true

  # Enable NAT Gateway
  # Expensive, but a requirement 
  enable_nat_gateway      = true
  single_nat_gateway      = true
  one_nat_gateway_per_az  = false
  enable_vpn_gateway      = true
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" : 1
    "kubernetes.io/cluster/${var.cluster_name}" : "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" : 1
    "kubernetes.io/cluster/${var.cluster_name}" : "shared"
  }
}

module "key_pair" {
  create = var.create_key_pair
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = var.key_pair_name_prefix
  create_private_key = true
}

module "eks" {
    source = "./modules/eks"
    aws_region = var.aws_region
    cluster_name = var.cluster_name
    vpc_id = module.vpc.vpc_id

    # TODO: Flip to private subnets and add a jump box for SSH
    vpc_subnets = module.vpc.public_subnets

    eks_key_pair_name = var.create_key_pair ? module.key_pair.key_pair_name : var.key_pair_name
}