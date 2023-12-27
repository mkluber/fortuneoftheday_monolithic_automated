provider "aws" {
  region = var.region
}

module "iam_iam-policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "fortunepolicy"
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
              "arn:aws:dynamodb:eu-central-1:385071190480:table/Fortunes"
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

  create_instance_profile = true

  role_name = "fortunerole"
  role_requires_mfa = false

  custom_role_policy_arns = module.iam_iam-policy.arn
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "fortunevpc"
  cidr = var.cidr

  azs             = var.azs
  public_subnets = var.public_subnets
  create_igw = "true"
  default_route_table_name = "fortuneroute"
}

module "security-group_http-80" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "http-sg"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.ingress_cidr_blocks
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = "fortunegroup"

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
  launch_template_name        = "fortunetemplate"
  launch_template_description = "Launch template example"
  update_default_version      = true
  target_group_arns         = [module.alb.target_groups["fortunetarget"].arn]

  image_id          = var.image_id
  instance_type     = var.instance_type
  security_groups   = module.security-group_http-80.security_group_id

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

  name    = "fortunelb"
  vpc_id  = module.vpc.vpc_id
  create_security_group = "false"
  security_groups = module.security-group_http-80.security_group_id
  subnets = module.vpc.public_subnets
  enable_deletion_protection = "false"

  listeners = {
    fortunelistener = {
    port     = 80
    protocol = "HTTP"
      forward = {
        target_group_key = "fortunetarget"
      }
    }
  }

  target_groups = {
    fortunetarget = {
      name             = "fortunetarget"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      create_attachment = "false"
    }
  }
}