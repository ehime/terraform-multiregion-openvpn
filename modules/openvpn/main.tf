data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_availability_zones" "current" {}

resource "aws_instance" "openvpn" {
  ami           = "${var.ami == "" ? data.aws_ami.ubuntu.id : var.ami}"
  instance_type = "${var.instance_type}"

  availability_zone = "${data.aws_availability_zones.current.id}"

  monitoring = false
  key_name   = "${aws_key_pair.terraformer.key_name}"

  tags {
    Name = "openvpn${var.deployment_suffix}"
  }

  security_groups = ["${aws_security_group.openvpn.name}"]
}

resource "aws_security_group" "openvpn" {
  name        = "openvpn${var.deployment_suffix}"
  description = "openvpn${var.deployment_suffix} security groups"
}

resource "aws_security_group_rule" "vpn-clients" {
  type              = "ingress"
  from_port         = 1194
  to_port           = 1194
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.openvpn.id}"
}

resource "aws_security_group_rule" "main_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.openvpn.id}"
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.openvpn.id}"
}

resource "aws_eip" "openvpn" {
  instance = "${aws_instance.openvpn.id}"
}

resource "aws_key_pair" "terraformer" {
  key_name   = "openvpn-key"
  public_key = "${file("${var.pub_key}")}"
}

output "ip" {
  value = "${aws_eip.openvpn.public_ip}"
}