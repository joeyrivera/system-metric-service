variable "ami" {
  description = "The AMI to use for EC2"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPN to use"
  type        = string
  default     = ""
}
variable "vpc_security_group_id" {
  description = "Default security groups"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Default subnet id"
  type        = string
  default     = ""
}