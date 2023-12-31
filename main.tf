provider "aws" {
  region = var.region
}

module "iam_iam-policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = var.iam_policy_name
  path        = "/"
  description = "Policy for the fortunes"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "dyna",
          "Effect": "Allow",
          "Action": [
              "dynamodb:GetItem",
              "dynamodb:Scan",
              "dynamodb:DeleteItem",
              "dynamodb:PutItem",
              "dynamodb:UpdateItem"
          ],
          "Resource": [
             "${module.dynamodb-table.dynamodb_table_arn}"
          ]
      }
  ]
}
EOF

  tags = {
    PolicyDescription = "Policy created using heredoc policy"
  }
}




module "iam_iam-assumable-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = var.iam_trusted_role_services
  create_instance_profile = true
  create_role = true
  role_name = var.iam_role_name
  role_requires_mfa = false

  custom_role_policy_arns = [module.iam_iam-policy.arn]
}

module "dynamodb-table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"


  name                        = var.dynamodb_table_name
  hash_key                    = var.dynamodb_table_hash_key
  range_key                   = var.dynamodb_table_range_key
  table_class                 = "STANDARD"
  deletion_protection_enabled = false

  attributes = [
    {
      name = var.dynamodb_table_hash_key
      type = "S"
    },
    {
      name = var.dynamodb_table_range_key
      type = "S"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.cidr

  azs             = var.azs
  public_subnets = var.public_subnets
  create_igw = "true"
  default_route_table_name = var.default_route_table_name
  map_public_ip_on_launch = "true"
}

module "security-group_http-80" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = var.security_group_name
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.ingress_cidr_blocks
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = var.auto_scaling_group_name

  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = module.vpc.public_subnets

  initial_lifecycle_hooks = [
    {
      name                  = "ExampleStartupLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 60
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                  = "ExampleTerminationLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 180
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name        = var.launch_template_name
  launch_template_description = "Launch template example"
  update_default_version      = true
  target_group_arns         = [module.alb.target_groups["fortunetarget"].arn]

  image_id          = var.image_id
  instance_type     = var.instance_type
  security_groups   = [module.security-group_http-80.security_group_id]

  # IAM role & instance profile
  create_iam_instance_profile = false
  iam_instance_profile_arn = module.iam_iam-assumable-role.iam_instance_profile_arn

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}


module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = var.load_balancer_name
  vpc_id  = module.vpc.vpc_id
  create_security_group = "false"
  security_groups = [module.security-group_http-80.security_group_id]
  subnets = module.vpc.public_subnets
  enable_deletion_protection = "false"

  listeners = {
    fortunelistener = {
    port     = 80
    protocol = "HTTP"
      forward = {
        target_group_key = var.target_group_name
      }
    }
  }

  target_groups = {
    fortunetarget = {
      name             = var.target_group_name
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      create_attachment = "false"
    }
  }
}