# provider "aws" {
#   region = var.region
# }

# resource "aws_lb" "fortunelb" {
#   name               = "fortunelb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = var.lb_security_groups
#   subnets            = var.lb_subnets

#   tags = {
#     Environment = "production"
#   }
# }



# resource "aws_lb_target_group" "fortunetargetgroup" {
#   name        = "fortunetargetgroup"
#   target_type = "instance"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = var.lb_target_group_vpc_id
# }

# resource "aws_lb_listener" "fortunelistener" {
#   load_balancer_arn = aws_lb.fortunelb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.fortunetargetgroup.arn
#   }
# }




# resource "aws_launch_template" "fortunetemplate" {
#   name = "fortunetemplate"

#   disable_api_stop        = true
#   disable_api_termination = true

#   iam_instance_profile {
#     name = var.instance_profile_name
#   }

#   image_id = var.ami_id

#   instance_type = var.instance_type

#   vpc_security_group_ids = var.launch_template_vpc_sg_ids

#   tag_specifications {
#     resource_type = "instance"

#     tags = {
#       Name = var.instance_name
#     }
#   }
# }






# resource "aws_autoscaling_group" "fortuneautogroup" {
#   name                      = "fortuneautogroup"
#   max_size                  = 3
#   min_size                  = 1
#   health_check_grace_period = 300
#   health_check_type         = "EC2"
#   desired_capacity          = 2
#   availability_zones = var.autoscaling_group_availability_zones

#   launch_template {
#     name = "fortunetemplate"
#   }

#   target_group_arns = [aws_lb_target_group.fortunetargetgroup.arn]

#   instance_maintenance_policy {
#     min_healthy_percentage = 90
#     max_healthy_percentage = 120
#   }

#   tag {
#     key                 = "foo"
#     value               = "bar"
#     propagate_at_launch = true
#   }

#   timeouts {
#     delete = "15m"
#   }

#   tag {
#     key                 = "lorem"
#     value               = "ipsum"
#     propagate_at_launch = false
#   }
# }













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

  image_id          = "ami-00eb698aea3e796bc"
  instance_type     = "t2.micro"
  # ebs_optimized     = true
  # enable_monitoring = true

  # IAM role & instance profile
  create_iam_instance_profile = false
  iam_instance_profile_arn = "arn:aws:iam::385071190480:instance-profile/FortuneWebServerDynamodbRole"
  # iam_role_name               = "example-asg"
  # iam_role_path               = "/ec2/"
  # iam_role_description        = "IAM role example"
  # iam_role_tags = {
  #   CustomIamRole = "Yes"
  # }
  # iam_role_policies = {
  #   AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  # }

  # block_device_mappings = [
  #   {
  #     # Root volume
  #     device_name = "/dev/xvda"
  #     no_device   = 0
  #     ebs = {
  #       delete_on_termination = true
  #       encrypted             = true
  #       volume_size           = 20
  #       volume_type           = "gp2"
  #     }
  #   }, {
  #     device_name = "/dev/sda1"
  #     no_device   = 1
  #     ebs = {
  #       delete_on_termination = true
  #       encrypted             = true
  #       volume_size           = 30
  #       volume_type           = "gp2"
  #     }
  #   }
  # ]

  # capacity_reservation_specification = {
  #   capacity_reservation_preference = "open"
  # }

  # cpu_options = {
  #   core_count       = 1
  #   threads_per_core = 1
  # }

  # credit_specification = {
  #   cpu_credits = "standard"
  # }

  # instance_market_options = {
  #   market_type = "spot"
  #   spot_options = {
  #     block_duration_minutes = 60
  #   }
  # }

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # network_interfaces = [
  #   {
  #     delete_on_termination = true
  #     description           = "eth0"
  #     device_index          = 0
  #     security_groups       = ["sg-12345678"]
  #   },
  #   {
  #     delete_on_termination = true
  #     description           = "eth1"
  #     device_index          = 1
  #     security_groups       = ["sg-12345678"]
  #   }
  # ]

  # placement = {
  #   availability_zone = "us-west-1b"
  # }

#   tag_specifications = [
#     {
#       resource_type = "instance"
#       tags          = { WhatAmI = "Instance" }
#     },
#     {
#       resource_type = "volume"
#       tags          = { WhatAmI = "Volume" }
#     },
#     {
#       resource_type = "spot-instances-request"
#       tags          = { WhatAmI = "SpotInstanceRequest" }
#     }
#   ]

#   tags = {
#     Environment = "dev"
#     Project     = "megasecret"
#   }
}




















module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "fortunelb"
  # vpc_id  = "vpc-abcde012"
  security_groups = ["sg-084412ea7d4375dde"]
  subnets = ["subnet-06cdce1d8e6b71368", "subnet-02449290dd55a46b1", "subnet-06d17cf8cdfc78514"]

  # Security Group
  # security_group_ingress_rules = {
  #   all_http = {
  #     from_port   = 80
  #     to_port     = 80
  #     ip_protocol = "tcp"
  #     description = "HTTP web traffic"
  #     cidr_ipv4   = "0.0.0.0/0"
  #   }
  #   all_https = {
  #     from_port   = 443
  #     to_port     = 443
  #     ip_protocol = "tcp"
  #     description = "HTTPS web traffic"
  #     cidr_ipv4   = "0.0.0.0/0"
  #   }
  # }
  # security_group_egress_rules = {
  #   all = {
  #     ip_protocol = "-1"
  #     cidr_ipv4   = "10.0.0.0/16"
  #   }
  # }

  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

listeners = {
  fortunelistener = {
  port     = 80
  protocol = "HTTP"
    forward = {
      target_group_key = "fortunetarget"
    }
  }
    # ex-http-https-redirect = {
    #   port     = 80
    #   protocol = "HTTP"
    #   redirect = {
    #     port        = "443"
    #     protocol    = "HTTPS"
    #     status_code = "HTTP_301"
    #   }
    # }
    # ex-https = {
    #   port            = 443
    #   protocol        = "HTTPS"
    #   certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"

    #   forward = {
    #     target_group_key = "ex-instance"
    #   }
    # }
}

  target_groups = {
    fortunetarget = {
      name_prefix      = "h1"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
    }
  }

  # tags = {
  #   Environment = "Development"
  #   Project     = "Example"
  # }
}