locals {
  # This will not work for all instance types just for the record
  # There's a hack on it, but I forget what it is
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  # tflint-ignore: terraform_unused_declarations
  validate_key_pair = var.create_key_pair || var.key_pair_name != null ? "Please provide a keypair or create one" : true

  helm_namespace = "jenkins"
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
  create  = var.create_key_pair
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = var.key_pair_name_prefix
  create_private_key = true
}

# This really shouldn't be a module, but I copy-pasted and did some serious refactoring 
# out of https://github.com/meyerkev/eks-tf-interview-template
#
# So it's a module now.  
module "eks" {
  source       = "../modules/eks"
  aws_region   = var.aws_region
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id

  # TODO: Flip to private subnets and add a jump box for SSH
  vpc_subnets = module.vpc.public_subnets

  eks_key_pair_name = var.create_key_pair ? module.key_pair.key_pair_name : var.key_pair_name

  # TODO: Make some of these install scripts architecture agnostic
  # Until then, force x86_64
  target_architecture = "x86_64"
}

# install jenkins
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = local.helm_namespace
  version    = "4.8.2"

  create_namespace = true

  values = [
    file("${path.module}/jenkins-values.yaml")
  ]

  set {
    name  = "controller.image"
    value = "jenkins/jenkins" # var.jenkins_image""
  }

  set {
    name  = "controller.tag"
    value = "2.430-jdk17" # var.jenkins_tag
  }

  set {
    name  = "agent.image"
    value = var.jenkins_agent_image
  }

  set {
    name  = "agent.tag"
    value = var.jenkins_agent_tag
  }

  wait          = true
  wait_for_jobs = true
}

# Everything about this is actually terrifying.  
# But I was having so many hours upon hours of problems with plugin versions that adding more plugins to the mix was just not an option
# So basically, we're doing a hack
# Specifically, the default jenkins serviceaccount is called default and now it has cluster-admin and can do whatever it wants
# Like say locally install a helm chart into the cluster that it's installed on
# namespaces is forbidden: User "system:serviceaccount:jenkins:default" cannot create resource "namespaces" in API group "" at the cluster scope
resource "kubernetes_cluster_role" "create_namespaces" {
  metadata {
    name = "create-namespaces"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "create_namespaces" {
  metadata {
    name = "create-namespaces"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.create_namespaces.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = local.helm_namespace
  }

  depends_on = [helm_release.jenkins]
}

resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = local.helm_namespace
  }

  depends_on = [helm_release.jenkins]
}

resource "aws_iam_policy" "jenkins_ecr" {
  name        = "jenkins-ecr"
  description = "Jenkins Policy"
  # Become a god of ECR
  # TODO: Pare this down to just what's needed to push app images
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


module "eks_jenkins_ecr_iam_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.30"
  role_name = "jenkins-ecr"

  role_policy_arns = {
    policy = aws_iam_policy.jenkins_ecr.arn
  }

  oidc_providers = {
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.helm_namespace}:default", "${local.helm_namespace}:jenkins"]
    }
  }
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = local.helm_namespace
  }
  depends_on = [helm_release.jenkins]
}

# So let's get this out of the way. 
# This is NOT the way to make this happen.  
# The actual way to make this happen is to dump these to SSM parameters and it's a whole thing
data "kubernetes_secret" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = local.helm_namespace
  }
  depends_on = [helm_release.jenkins]
}

# 

# Things we're not doing
# HTTPS
# An actual stable URL (which is why we had to do that thing above)
# Proper ALB's