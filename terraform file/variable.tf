# variables.tf

variable "region" {
  description = "AWS region"
  default     = "ap-northeast-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/18"
}

variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  default     = "10.0.0.0/19"
}

variable "ami_id" {
  description = "AMI ID for instances"
  default     = "ami-09a81b370b76de6a2"
}

variable "instance_type_ci" {
  description = "Instance type for ci_instance"
  default     = "t2.micro"
}

variable "instance_type_cd" {
  description = "Instance type for cd_instance"
  default     = "t2.medium"
}

variable "ssh_cidr_block" {
  description = "CIDR block for Secure Shell access"
  default     = "0.0.0.0/0"
}

variable "http_cidr_block" {
  description = "CIDR block for HTTP access"
  default     = "0.0.0.0/0"
}

variable "https_cidr_block" {
  description = "CIDR block for HTTPS access"
  default     = "0.0.0.0/0"
}

variable "docker_username" {
  description = "Docker username for pushing images"
  default     = "YourDockerUsername"
}

variable "docker_password" {
  description = "Docker password for pushing images"
  default     = "YourDockerPassword"
}
