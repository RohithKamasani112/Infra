terraform {
required_version = ">= 1.0"

required_providers {
aws = {
source  = "hashicorp/aws"
version = "~> 5.0"
}
kubernetes = {
source  = "hashicorp/kubernetes"
version = "~> 2.23"
}
helm = {
source  = "hashicorp/helm"
version = "~> 2.11"
}
}
}

provider "aws" {
region = var.aws_region
}

provider "kubernetes" {
host                   = module.eks.cluster_endpoint
cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
kubernetes {
host                   = module.eks.cluster_endpoint
cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
token                  = data.aws_eks_cluster_auth.this.token
}
}

data "aws_eks_cluster_auth" "this" {
name = module.eks.cluster_name
}