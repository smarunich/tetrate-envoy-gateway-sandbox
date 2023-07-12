data "aws_availability_zones" "available" {}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.k8s_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  create_cloudwatch_log_group     = false

  vpc_id     = var.vpc_id
  subnet_ids = var.vpc_subnets

  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["m5.xlarge"]
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }

    tags = merge(var.tags, {
      Name = "${var.name_prefix}_default"
    })
  }

  cluster_addons = {
    coredns = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      configuration_values = jsonencode({
        "controller" = {
          "extraVolumeTags" = var.tags
        }
      })
    }
    vpc-cni = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {
    tetrate_sandbox_blue = {
      min_size     = 3
      max_size     = 5
      desired_size = 3
    }
  }

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "all"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 0
      type                       = "egress"
      source_node_security_group = true
    }

    inress_ec2_tcp = {
      description                   = "Access EKS externally"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      cidr_blocks                   = ["0.0.0.0/0"]
      source_cluster_security_group = false
    }

  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}"
  })

  putin_khuylo = true

}

module "eks_auth" {
  source = "aidanmelen/eks-auth/aws"
  eks    = module.eks
  map_roles = [
    {
      rolearn  = var.jumpbox_iam_role_arn
      username = "eks-admin"
      groups   = ["system:masters"]
    },
  ]
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "local_file" "gen_kubeconfig_sh" {
  content         = "eksctl utils write-kubeconfig --cluster ${var.cluster_name} --region ${data.aws_availability_zones.available.id} --kubeconfig ${var.cluster_name}-kubeconfig"
  filename        = "${var.output_path}/generate-${var.cluster_name}-kubeconfig.sh"
  file_permission = "0755"
}