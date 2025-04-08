variable "create" {
  description = "Controla si se deben crear los recursos"
  type        = bool
}

variable "create_ecr" {
  description = "Controla si se deben crear los recursos"
  type        = bool
}

variable "ecr_name" {
  description = "Nombre del repositorio ECR"
  type        = string
}

variable "namespace" {
  description = "Prefijo común para nombrar recursos"
  type        = string
}

variable "app_namespace" {
  description = "Namespace de Kubernetes para las aplicaciones Fargate"
  type        = string
  default     = "default"
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Lista de subnets para el EKS y el ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Lista de subnets para el EKS y el ALB"
  type        = list(string)
}


variable "allowed_ip" {
  description = "IP pública autorizada para acceder al ALB (formato CIDR)"
  type        = string
}

variable "public_access_cidrs" {
  description = "CIDRs permitidos para acceso público al API server de EKS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "endpoint_private_access" {
  description = "Habilitar acceso privado al API server"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Habilitar acceso público al API server"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.28"
}

variable "enabled_cluster_log_types" {
  description = "Tipos de logs habilitados para el cluster"
  type        = list(string)
  default     = ["api", "audit"]
}

variable "tags" {
  description = "Etiquetas comunes para los recursos"
  type        = map(string)
  default     = {}
}

variable "fargate_additional_policy_arns" {
  description = "ARNs de políticas adicionales para el perfil de Fargate"
  type        = list(string)
}