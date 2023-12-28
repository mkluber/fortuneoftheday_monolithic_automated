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

variable "iam_policy_name" {
  description = "Name of the created IAM policy"
}

variable "iam_trusted_role_services" {
  description = "The AWS services that the role is attached to"
}

variable "iam_role_name" {
  description = "Name of the created IAM role"
}

variable "dynamodb_table_name" {
  description = "Name of the created dynamodb table"
}

variable "dynamodb_table_hash_key" {
  description = "Hash key name of the dynamodb table"
}

variable "dynamodb_table_range_key" {
  description = "Range key name of the dynamodb table"
}

variable "vpc_name" {
  description = "Name of the created VPC"
}

variable "default_route_table_name" {
  description = "Name of the default route table"
}

variable "security_group_name" {
  description = "Name of the created security group"
}

variable "auto_scaling_group_name" {
  description = "Name of the created auto scaling group"
}

variable "launch_template_name" {
  description = "Name of the created launch template"
}

variable "load_balancer_name" {
  description = "Name of the created load balancer"
}

variable "target_group_name" {
  description = "Name of the created target group"
}