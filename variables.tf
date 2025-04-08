variable "create" {
  type = bool
}

variable "create_ecr" {
  type = bool
}

variable "ecr_name" {
  type = string
}
variable "namespace" {
  type = string
}

variable "environment" {
  type = string
}

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "kubernetes_version" {
  type = string
}

variable "enabled_cluster_log_types" {
  type    = list(string)
  default = []
}

variable "endpoint_private_access" {
  type    = bool
  default = false
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "tags" {
  type    = map(string)
  default = {}
}