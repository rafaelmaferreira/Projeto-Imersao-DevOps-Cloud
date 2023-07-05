terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.2"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name                = "vpc"
  cidr                = var.vpc_cidr
  private_subnets     = var.private_subnet_cidr_blocks
  public_subnets      = var.public_subnet_cidr_blocks
  azs                 = var.azs

  enable_nat_gateway  = true
  single_nat_gateway  = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/eks" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/imersao-eks" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/imersao-eks" = "shared"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name        = "eks-imersao"
  cluster_version     = "1.27"

  subnet_ids                      = module.vpc.private_subnets
  vpc_id                          = module.vpc.vpc_id
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    live = {
      min_size              = 1
      max_size              = 3
      desired_size          = 1

      instance_types = ["t3.micro"]
    }
  }
}

variable "vpc_cidr" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}
variable "azs" {}
variable "region" {}