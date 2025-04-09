resource "aws_eks_cluster" "this" {
  count                     = var.create ? 1 : 0
  name                      = format("%s-eks-cluster", var.namespace)
  role_arn                  = aws_iam_role.cluster_role[0].arn
  version                   = var.kubernetes_version
  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.eks[0].id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  tags = merge(var.tags, {
    Name = format("%s-eks-cluster", var.namespace)
  })
}

resource "aws_security_group" "eks" {
  count       = var.create ? 1 : 0
  name        = format("%s-eks-sg", var.namespace)
  description = "EKS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip, "10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = format("%s-eks-sg", var.namespace)
  })
}

resource "aws_iam_role" "cluster_role" {
  count = var.create ? 1 : 0
  name  = format("%s-eks-role", var.namespace)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "fargate_execution_role" {
  count = var.create ? 1 : 0
  name  = format("%s-fargate-execution", var.namespace)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "custom_fargate_policies" {
  for_each   = var.create ? toset(var.fargate_additional_policy_arns) : toset([])
  role       = aws_iam_role.fargate_execution_role[0].name
  policy_arn = each.value
}

resource "aws_eks_fargate_profile" "default" {
  count                  = var.create ? 1 : 0
  cluster_name           = aws_eks_cluster.this[0].name
  fargate_profile_name   = format("%s-fargate", var.namespace)
  pod_execution_role_arn = aws_iam_role.fargate_execution_role[0].arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = var.namespace
  }

  selector {
    namespace = "kube-system"
  }

  depends_on = [
    aws_iam_role_policy_attachment.custom_fargate_policies
  ]
}



resource "aws_ecr_repository" "this" {
  count = var.create_ecr ? length(var.ecr_name) : 0

  name = var.ecr_name[count.index]

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = var.tags
}
