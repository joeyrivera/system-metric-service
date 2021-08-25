variable "vpc_id" {
  description = "VPN to use"
  type        = string
}
variable "vpc_security_group_id" {
  description = "Default security groups"
  type        = string
}

variable "subnet_id" {
  description = "Default subnet id"
  type        = string
}

variable "subnet_ids" {
  description = "All subnet ids"
  type        = list(string)
}

variable "ssh_key" {
  description = "Public SSH key"
  type        = string
}

variable "ami" {
  description = "AMI for EC2 instance"
  type        = string
}