variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile to use (e.g. for SSO)"
  default     = "default"
}

variable "vpc_id" {
  description = "VPC ID to deploy into (since no default VPC exists)"
  type        = string
}

variable "db_name" {
  description = "Database name"
  default     = "sonardashboard"
}

variable "db_username" {
  description = "Database master username"
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password"
  sensitive   = true
}

variable "github_repo_url" {
  description = "URL of the GitHub repository for CodeBuild source"
  type        = string
  default     = "https://github.com/deepaknet5/sonardashboard.git"
}
