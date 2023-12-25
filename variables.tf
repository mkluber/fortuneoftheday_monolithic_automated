variable "region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "cidr" {
  description = "CIDR value assigned to the VPC"
}

variable "azs" {
  description = "Availability zones assigned to the VPC"
}

variable "public_subnets" {
  description = "Public subnets created by the VPC"
}

variable "ingress_cidr_blocks" {
  description = "The cidr block used for inbound rules in the newly created security group"
}

variable "image_id" {
  description = "AMI used by the EC2 instances"
}

variable "instance_type" {
  description = "The type of instance for EC2 instances"
}