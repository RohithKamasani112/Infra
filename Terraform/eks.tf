module "eks" {
source  = "terraform-aws-modules/eks/aws"
version = "~> 20.0"

cluster_name    = var.cluster_name
cluster_version = "1.28"

vpc_id                   = module.vpc.vpc_id
subnet_ids               = module.vpc.private_subnets
control_plane_subnet_ids = module.vpc.private_subnets

# Enable both private and public access for initial setup
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# Enable IRSA for service accounts
enable_irsa = true

# Cluster security group
cluster_security_group_additional_rules = {
ingress_nodes_ephemeral_ports_tcp = {
description                = "Node groups to cluster API"
protocol                   = "tcp"
from_port                  = 1025
to_port                    = 65535
type                       = "ingress"
source_node_security_group = true
}
}

# Node security group
node_security_group_additional_rules = {
ingress_self_all = {
description = "Node to node all ports/protocols"
protocol    = "-1"
from_port   = 0
to_port     = 0
type        = "ingress"
self        = true
}
egress_all = {
description      = "Node all egress"
protocol         = "-1"
from_port        = 0
to_port          = 0
type             = "egress"
cidr_blocks      = ["0.0.0.0/0"]
ipv6_cidr_blocks = ["::/0"]
}
}

# EKS Managed Node Group(s)
eks_managed_node_group_defaults = {
instance_types = ["t3.medium"]
ami_type       = "AL2_x86_64"
capacity_type  = "ON_DEMAND"
}

eks_managed_node_groups = {
general = {
name = "general"

instance_types = ["t3.medium"]
ami_type       = "AL2_x86_64"
capacity_type  = "ON_DEMAND"

min_size     = 1
max_size     = 3
desired_size = 2

labels = {
role = "general"
}

tags = {
Environment = var.environment
Project     = var.project_name
}
}
}

# Cluster access entry
# To add the current caller identity as an administrator
enable_cluster_creator_admin_permissions = true

tags = {
Environment = var.environment
Project     = var.project_name
}
}
