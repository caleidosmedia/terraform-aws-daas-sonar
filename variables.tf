variable "vpc_id" {
  description = "VPC ID"
}

variable "subnets" {
  description = "List of IDs of private subnets"
}

variable "public_subnets" {
  description = "List of IDs of public subnets"
}

variable "name" {
  description = "Name"
  default     = "sonar"
}

variable "container_port" {
  description = "The port number on the container"
  default     = 9000
}

variable "container_image" {
  description = "Sonarqube container image"
  default     = "public.ecr.aws/docker/library/sonarqube:lts-community"
}

variable "health_check_path" {
  description = "The path to register with the Application Load Balancer"
  default     = "/"
}

variable "alb_tls_cert_arn" {
  description = "ARN of ACM certificate"
}

variable "alb_logs_bucket_name" {
  description = "Name for s3 bucket for ALB logs"
}

variable "alb_root_account_id" {
  description = "Valid account id. Full list -> https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html"
  default     = "127311923021"
}

variable "desired_count" {
  description = "How many instances of this task should we run across our cluster"
  default     = 1
}

variable "task_memory" {
  description = "Desired memory for the SonarQube task"
  default     = 2048
}

variable "task_cpu" {
  description = "Desired CPU for the SonarQube task"
  default     = 1024
}

variable "internal_load_balancer" {
  description = "If true, the LB will be internal"
  type        = bool
  default     = true
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group"
}