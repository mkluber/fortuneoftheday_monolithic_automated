provider "aws" {
  region = var.region
}

data "aws_ami" "fortuneami" {

  most_recent = true
  owners = ["self"]

  filter {
    name   = "name"
    values = ["FortuneWebServerImage2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_instance" "fortunevm" {
  ami           = data.aws_ami.fortuneami.id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}
