provider "aws" {
  region = var.region
}

resource "aws_lb" "fortunelb" {
  name               = "fortunelb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.lb_security_groups
  subnets            = var.lb_subnets

  tags = {
    Environment = "production"
  }
}



resource "aws_lb_target_group" "fortunetargetgroup" {
  name        = "fortunetargetgroup"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.lb_target_group_vpc_id
}

resource "aws_lb_listener" "fortunelistener" {
  load_balancer_arn = aws_lb.fortunelb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fortunetargetgroup.arn
  }
}




resource "aws_launch_template" "fortunetemplate" {
  name = "fortunetemplate"

  disable_api_stop        = true
  disable_api_termination = true

  iam_instance_profile {
    name = var.instance_profile_name
  }

  image_id = var.ami_id

  instance_type = var.instance_type

  vpc_security_group_ids = var.launch_template_vpc_sg_ids

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = var.instance_name
    }
  }
}






resource "aws_autoscaling_group" "fortuneautogroup" {
  name                      = "fortuneautogroup"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  availability_zones = var.autoscaling_group_availability_zones

  launch_template {
    name = "fortunetemplate"
  }

  target_group_arns = [aws_lb_target_group.fortunetargetgroup.arn]

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}