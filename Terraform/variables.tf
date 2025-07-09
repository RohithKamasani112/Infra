variable "aws_region" {
description = "The AWS region to deploy the resources."
type        = string
default     = "us-west-2"
}

variable "project_name" {
description = "The name of the project for resource tagging."
type        = string
default     = "eks-project"
}

variable "environment" {
description = "The environment for resource tagging (e.g., dev, prod)."
type        = string
default     = "dev"
}

variable "cluster_name" {
description = "Name of the EKS cluster."
type        = string
default     = "my-eks-cluster"
}

variable "vpc_cidr" {
description = "CIDR block for the VPC."
type        = string
default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
description = "List of CIDR blocks for public subnets."
type        = list(string)
default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
description = "List of CIDR blocks for private subnets."
type        = list(string)
default     = ["10.0.3.0/24", "10.0.4.0/24"]
}