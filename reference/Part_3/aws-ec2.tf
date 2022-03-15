
data "aws_vpc" "web_vpc" {
  default = true
}

resource "aws_security_group" "web_security_group" {
  vpc_id = data.aws_vpc.web_vpc.id
}

resource "aws_security_group_rule" "web_security_group_rule_egress" {
  security_group_id = aws_security_group.web_security_group.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_security_group_rule_ingress" {
  security_group_id = aws_security_group.web_security_group.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

output "ec2instance" {
  value = aws_instance.web.public_ip
}

resource "random_string" "user" {
  length  = 6
  upper   = false
  lower   = true
  number  = true
  special = false
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${random_string.user.result}"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  key_name = aws_key_pair.deployer.id
  vpc_security_group_ids = [aws_security_group.web_security_group.id]
  associate_public_ip_address = true
}

