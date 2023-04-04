resource "tls_private_key" "tls_ed25519" {
  algorithm = "ED25519"
}

resource "tls_private_key" "tls_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  # choose between ED25519 and RSA
  ssh_key = (
    var.ssh_algorithm == "ED25519" ?
    tls_private_key.tls_ed25519 :
    tls_private_key.tls_rsa
    )
}

resource "local_file" "ssh_public_key" {
  content  = local.ssh_key.private_key_openssh
  filename = var.key_path
  provisioner "local-exec" {
    command = "chmod 0600 ${local_file.ssh_public_key.filename}"
  }
}

resource "aws_key_pair" "key" {
  key_name   = var.cluster_name
  public_key = local.ssh_key.public_key_openssh
  tags       = var.global_tags
}

data "http" "myip" {
  url = "https://api.ipify.org"
}

resource "aws_security_group" "common" {
  name        = "${var.cluster_name}-common"
  description = "mke cluster common rules"
  vpc_id      = var.vpc_id
  tags        = var.global_tags

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port   = var.controller_port
    to_port     = var.controller_port
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
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 33000
    to_port     = 33003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "open_myip" {
  # conditionally add this rule to SG 'common'
  security_group_id = aws_security_group.common.id
  count             = var.open_sg_for_myip ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "mke_role" {
  name               = "${var.cluster_name}_MKE_role"
  tags               = var.global_tags
  assume_role_policy = file("${path.module}/mke_role.json")
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.cluster_name}_MKE_profile"
  role = aws_iam_role.mke_role.name
}

resource "aws_iam_role_policy" "mke_policy" {
  name = "${var.cluster_name}_MKE_policy"
  role = aws_iam_role.mke_role.id
  # Ref: https://docs.mirantis.com/mke/3.6/install/install-aws/aws-prerequisites.html
  policy = file("${path.module}/mke_policy.json")
}

# Pulling from the data source saves us trying to attach to the policy.
# Problematic for 'docker-testing', even if not a problem for 'IAM_config_access'.
# This approach lets us pull the data from the policy and use it to create the
# 'ebs_csi_driver_policy', below. Avoids needing users to have more privs than
# necessary.
data "aws_iam_policy" "AmazonEBSCSIDriverPolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy" "ebs_csi_driver_policy" {
  name   = "${var.cluster_name}_EBSCSIDriverPolicy"
  role   = aws_iam_role.mke_role.id
  policy = data.aws_iam_policy.AmazonEBSCSIDriverPolicy.policy
}
