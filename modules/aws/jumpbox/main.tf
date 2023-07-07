resource "aws_security_group" "jumpbox_sg" {
  description = "Allow incoming connections to the lab jumpbox."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_jumpbox_sg"
  })

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9080
    to_port     = 9080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role_policy" "jumpbox_iam_policy" {
  name   = "${var.name_prefix}_jumpbox_policy"
  role   = aws_iam_role.jumpbox_iam_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
              "ec2:AssignPrivateIpAddresses",
              "ec2:AttachNetworkInterface",
              "ec2:CreateNetworkInterface",
              "ec2:DeleteNetworkInterface",
              "ec2:DescribeInstances",
              "ec2:DescribeInstanceTypes",
              "ec2:DescribeTags",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DetachNetworkInterface",
              "ec2:ModifyNetworkInterfaceAttribute",
              "ec2:UnassignPrivateIpAddresses",
              "autoscaling:DescribeAutoScalingGroups",
              "autoscaling:DescribeLaunchConfigurations",
              "autoscaling:DescribeTags",
              "ec2:DescribeInstances",
              "ec2:DescribeRegions",
              "ec2:DescribeRouteTables",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeSubnets",
              "ec2:DescribeVolumes",
              "ec2:CreateSecurityGroup",
              "ec2:CreateTags",
              "ec2:CreateVolume",
              "ec2:ModifyInstanceAttribute",
              "ec2:ModifyVolume",
              "ec2:AttachVolume",
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:CreateRoute",
              "ec2:DeleteRoute",
              "ec2:DeleteSecurityGroup",
              "ec2:DeleteVolume",
              "ec2:DetachVolume",
              "ec2:RevokeSecurityGroupIngress",
              "ec2:DescribeVpcs",
              "ec2:DescribeClassicLinkInstances",
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:AttachLoadBalancerToSubnets",
              "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
              "elasticloadbalancing:CreateLoadBalancer",
              "elasticloadbalancing:CreateLoadBalancerPolicy",
              "elasticloadbalancing:CreateLoadBalancerListeners",
              "elasticloadbalancing:ConfigureHealthCheck",
              "elasticloadbalancing:DeleteLoadBalancer",
              "elasticloadbalancing:DeleteLoadBalancerListeners",
              "elasticloadbalancing:DescribeLoadBalancers",
              "elasticloadbalancing:DescribeLoadBalancerAttributes",
              "elasticloadbalancing:DetachLoadBalancerFromSubnets",
              "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
              "elasticloadbalancing:ModifyLoadBalancerAttributes",
              "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
              "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:CreateListener",
              "elasticloadbalancing:CreateTargetGroup",
              "elasticloadbalancing:DeleteListener",
              "elasticloadbalancing:DeleteTargetGroup",
              "elasticloadbalancing:DescribeListeners",
              "elasticloadbalancing:DescribeLoadBalancerPolicies",
              "elasticloadbalancing:DescribeTargetGroups",
              "elasticloadbalancing:DescribeTargetHealth",
              "elasticloadbalancing:ModifyListener",
              "elasticloadbalancing:ModifyTargetGroup",
              "elasticloadbalancing:RegisterTargets",
              "elasticloadbalancing:DeregisterTargets",
              "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
              "elasticloadbalancing:DescribeInstanceHealth",
              "iam:CreateServiceLinkedRole",
              "kms:DescribeKey",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:GetRepositoryPolicy",
              "ecr:DescribeRepositories",
              "ecr:ListImages",
              "ecr:BatchGetImage",
              "ecr:CreateRepository",
              "ecr:InitiateLayerUpload",
              "ecr:UploadLayerPart",
              "ecr:CompleteLayerUpload",
              "ecr:PutImage",
              "route53:ChangeResourceRecordSets",
              "route53:ChangeTagsForResource",
              "route53:ListResourceRecordSets",
              "route53:ListHostedZone"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role" "jumpbox_iam_role" {
  name               = "${var.name_prefix}_jumpbox_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = merge(var.tags, {
    Name = "${var.name_prefix}_jumpbox_iam_role"
  })
}

resource "aws_iam_instance_profile" "jumpbox_iam_profile" {
  name = "${var.name_prefix}_jumpbox_profile"
  role = aws_iam_role.jumpbox_iam_role.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_jumpbox_profile"
  })
}




resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tetrateadmin_key_pair" {
  key_name   = "${var.name_prefix}_generated"
  public_key = tls_private_key.generated.public_key_openssh

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_tetrateadmin_key"
  })
}

data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_availability_zones" "available" {}

resource "aws_instance" "jumpbox" {
  ami               = data.aws_ami.ubuntu.id
  availability_zone = data.aws_availability_zones.available.names[0]
  instance_type     = "t2.medium"

  key_name                    = aws_key_pair.tetrateadmin_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.jumpbox_sg.id]
  subnet_id                   = var.vpc_subnet
  associate_public_ip_address = true
  source_dest_check           = false

  root_block_device {
    volume_type           = "standard"
    volume_size           = "20"
    delete_on_termination = "true"
  }

  user_data = base64encode(templatefile("${path.module}/jumpbox.userdata", {
    jumpbox_username            = var.jumpbox_username
    tetrate_version             = var.tetrate_version
    tetrate_image_sync_username = var.tetrate_image_sync_username
    tetrate_image_sync_apikey   = var.tetrate_image_sync_apikey
    docker_login                = "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.registry}"
    registry                    = var.registry
    registry_name               = var.registry_name
    region                      = var.region
    pubkey                      = tls_private_key.generated.public_key_openssh
  }))
  iam_instance_profile = aws_iam_instance_profile.jumpbox_iam_profile.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_jumpbox"
  })

  volume_tags = merge(var.tags, {
    Name = "${var.name_prefix}_jumpbox"
  })

}

resource "local_file" "tetrateadmin_pem" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${var.output_path}/${regex(".+-\\d+", "${var.name_prefix}")}-aws-${var.jumpbox_username}.pem"
  depends_on      = [tls_private_key.generated]
  file_permission = "0600"
}

resource "local_file" "ssh_jumpbox" {
  content         = "ssh -i ${regex(".+-\\d+", "${var.name_prefix}")}-aws-${var.jumpbox_username}.pem -l ${var.jumpbox_username} ${aws_instance.jumpbox.public_ip}"
  filename        = "${var.output_path}/ssh-to-aws-${regex(".+-\\d+", "${var.name_prefix}")}-jumpbox.sh"
  file_permission = "0755"
}

