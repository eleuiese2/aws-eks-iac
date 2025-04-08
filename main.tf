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
    from_port   = 50051
    to_port     = 50051
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
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

resource "aws_lb" "grpc_alb" {
  count                      = var.create ? 1 : 0
  name                       = format("%s-grpc-alb", var.namespace)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.eks[0].id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false
  tags = merge(var.tags, {
    Name = format("%s-grpc-alb", var.namespace)
  })
}

resource "aws_lb_target_group" "grpc_tg" {
  count    = var.create ? 1 : 0
  name     = format("%s-grpc-tg", var.namespace)
  port     = 50051
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200"
  }
  tags = merge(var.tags, {
    Name = format("%s-grpc-tg", var.namespace)
  })
}

resource "aws_lb_listener" "grpc_listener" {
  count             = var.create ? 1 : 0
  load_balancer_arn = aws_lb.grpc_alb[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grpc_tg[0].arn
  }
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
    namespace = var.app_namespace
  }

  selector {
    namespace = "kube-system"
  }

  depends_on = [
    aws_iam_role_policy_attachment.fargate_policy_attachment,
    aws_iam_role_policy_attachment.custom_fargate_policies
  ]
}

resource "aws_iam_role" "alb_controller" {
  count = var.create ? 1 : 0
  name  = format("%s-alb-controller", var.namespace)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
  count      = var.create ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.alb_controller[0].name
}



resource "aws_ecr_repository" "this" {
  count = var.create_ecr ? 1 : 0

  name = var.ecr_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}