resource "aws_eks_cluster" "this" {
  count                     = var.create ? 1 : 0
  name                      = format("%s-eks", var.namespace)
  role_arn                  = aws_iam_role.cluster_role[0].arn
  version                   = var.kubernetes_version
  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.eks[0].id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  tags = merge(var.tags, {
    Name = format("%s-eks", var.namespace)

  })
}

resource "aws_security_group" "eks" {
  count       = var.create ? 1 : 0
  name        = format("%s-eks-sg", var.namespace)
  description = "EKS security group"
  vpc_id      = var.vpc_id

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
  name  = format("%s-eks-fargate-execution-role", var.namespace)
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

resource "aws_iam_role_policy_attachment" "fargate_policy_attachment" {
  count      = var.create ? 1 : 0
  role       = aws_iam_role.fargate_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_eks_fargate_profile" "default" {
  count                  = var.create ? 1 : 0
  cluster_name           = aws_eks_cluster.this[0].name
  fargate_profile_name   = format("%s-eks-fargate-profile", var.namespace)
  pod_execution_role_arn = aws_iam_role.fargate_execution_role[0].arn
  subnet_ids             = var.subnet_ids

  selector {
    namespace = "default"
  }

  selector {
    namespace = "kube-system"
  }

  depends_on = [aws_iam_role_policy_attachment.fargate_policy_attachment]
}

resource "aws_ecr_repository" "this" {
  count = var.create ? 1 : 0

  name = var.ecr_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}