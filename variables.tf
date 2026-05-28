variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type_web" {
  description = "Instance type for bastion and web servers"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_db" {
  description = "Instance type for database server"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = "techcorp-key"
}

variable "my_ip" {
  description = "Your current IP address for bastion SSH access (format: x.x.x.x/32)"
  type        = string
}