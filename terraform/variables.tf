variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name identifier"
  type        = string
  default     = "devsecops-iac"
}
