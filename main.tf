provider "aws" {
  region = var.region
}

# data "aws_ami" "fortuneami" {

#   most_recent = true
#   owners = ["self"]

#   filter {
#     name   = "name"
#     values = ["FortuneWebServerImage2"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

# }

# resource "aws_instance" "fortunevm" {
#   ami           = data.aws_ami.fortuneami.id
#   instance_type = var.instance_type

#   tags = {
#     Name = var.instance_name
#   }
# }


resource "aws_lb" "fortunelb" {
  name               = "fortunelb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-084412ea7d4375dde"]
  subnets            = ["subnet-06cdce1d8e6b71368", "subnet-02449290dd55a46b1", "subnet-06d17cf8cdfc78514"]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}



resource "aws_lb_target_group" "fortunetargetgroup" {
  name        = "fortunetargetgroup"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = "vpc-0a2da1530815bf09c"
}

resource "aws_lb_listener" "front_end" {
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
    name = "FortuneWebServerDynamodbRole"
  }

  image_id = "ami-00eb698aea3e796bc"

  instance_type = "t2.micro"

  vpc_security_group_ids = ["sg-084412ea7d4375dde", "sg-0270cf20e5d2b1fd8"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test"
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
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  launch_template {
    name = "fortunetemplate"
  }

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