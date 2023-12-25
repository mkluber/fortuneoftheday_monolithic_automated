provider "aws" {
  region = var.region
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
  vpc_zone_identifier       = ["subnet-06cdce1d8e6b71368", "subnet-02449290dd55a46b1", "subnet-06d17cf8cdfc78514"]

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

  image_id          = "ami-00eb698aea3e796bc"
  instance_type     = "t2.micro"
  security_groups   = ["sg-084412ea7d4375dde"]

  # IAM role & instance profile
  create_iam_instance_profile = false
  iam_instance_profile_arn = "arn:aws:iam::385071190480:instance-profile/FortuneWebServerDynamodbRole"

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
  vpc_id  = "vpc-0a2da1530815bf09c"
  create_security_group = "false"
  security_groups = ["sg-084412ea7d4375dde"]
  subnets = ["subnet-06cdce1d8e6b71368", "subnet-02449290dd55a46b1", "subnet-06d17cf8cdfc78514"]
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