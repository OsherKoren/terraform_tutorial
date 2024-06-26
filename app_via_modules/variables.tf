# General Variables

variable "region" {
  description = "Default region for provider"
  type        = string
  default     = "us-east-2"
}

variable "app_name" {
  description = "Name of the web application"
  type        = string
  default     = "terraform-tutorial"
}


# EC2 Variables

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Ubuntu 20.04 LTS // us-east-2
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

# S3 Variables

variable "bucket_prefix" {
  description = "prefix of s3 bucket for app data"
  type        = string
  default     = "terraform-tutorial"
}

# Route 53 Variables

variable "create_dns_zone" {
  description = "If true, create new route53 zone, if false read existing route53 zone"
  type        = bool
  default     = false
}

variable "domain" {
  description = "Domain for website"
  type        = string
  default     = "terraformtutorialwebapp"
}


# RDS Variables

variable "db_name" {
  description = "Name of DB"
  type        = string
  default     = "terraformtutorial"
}

variable "db_user" {
  description = "Username for DB"
  type        = string
  default     = "foo"
}

variable "db_pass" {
  description = "Password for DB"
  type        = string
  default     = "foobarbaz"
  # sensitive   = true
}
