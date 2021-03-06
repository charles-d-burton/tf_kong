data "aws_vpc" "selected_vpc" {
  id = "${var.vpc_id}"
}

data "template_file" "kong_config" {
  template = "${file("${path.module}/kong_setup.sh")}"

  vars {
    pg_host   = "${aws_db_instance.kong_db.address}"
    pg_pass   = "${var.pg_pass}"
    pg_user   = "kong"
    pg_db     = "kong"
    log_group = "${var.log_group_path}/${var.service_name}"
  }
}

#Get the latest ubuntu ami
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ubuntu_ami_name}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#Get the latest amazon linux ami
data "aws_ami" "amazon" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.amazon_ami_name}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Canonical
}
