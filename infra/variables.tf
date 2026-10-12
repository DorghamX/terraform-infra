variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "eks-lab"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "kubernetes_version" {
  type    = string
  default = "1.37"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "true = one NAT gateway (cheap, dev). false = one per AZ (highly available)."
}

variable "api_allowed_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the public EKS API endpoint. Restrict to your own IP for real use."
}

variable "alert_email" {
  type        = string
  description = "Email address that receives security alarm notifications"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "enable_interface_endpoints" {
  type        = bool
  default     = false
  description = "Create interface VPC endpoints (ECR, STS, Logs). They add hourly cost, so they are off by default."
}
