module "vpc" {
source  = "terraform-aws-modules/vpc/aws"
version = "~> 5.0"

name = "${var.project_name}-vpc-${var.environment}"
cidr = var.vpc_cidr

azs              = ["${var.aws_region}a", "${var.aws_region}b"]
public_subnets   = var.public_subnet_cidrs
private_subnets  = var.private_subnet_cidrs

enable_nat_gateway = true
single_nat_gateway = true
enable_dns_hostnames = true
enable_dns_support   = true

# Required for EKS
public_subnet_tags = {
  "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  "kubernetes.io/role/elb"                    = "1"
}

private_subnet_tags = {
  "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  "kubernetes.io/role/internal-elb"           = "1"
}

tags = {
Environment = var.environment
Project     = var.project_name
"kubernetes.io/cluster/${var.cluster_name}" = "shared"
}
}