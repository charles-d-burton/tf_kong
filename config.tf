data "aws_vpc" "selected_vpc" {
  id = "${var.vpc_id}"
}

data "template_file" "kong_config" {
  template = "${file("${path.module}/kong_setup.sh")}"

  vars {
    pg_host = "${aws_db_instance.kong_db.address}"
    pg_pass = "${var.pg_pass}"
    pg_user = "kong"
    pg_db   = "kong"
  }
}
