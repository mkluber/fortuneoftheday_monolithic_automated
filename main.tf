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

resource "aws_launch_template" "fortunetemplate" {
  name = "fortunetemplate"

  disable_api_stop        = true
  disable_api_termination = true

  ebs_optimized = true

  iam_instance_profile {
    name = "FortuneWebServerDynamodbRole"
  }

  image_id = "ami-00eb698aea3e796bc"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t2.micro"

  placement {
    availability_zone = "eu-central-1"
  }

  vpc_security_group_ids = ["sg-084412ea7d4375dde", "sg-0270cf20e5d2b1fd8"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test"
    }
  }
}