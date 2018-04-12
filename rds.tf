resource "aws_security_group" "kong_sg" {
  name        = "tf_kong_postgres_sg"
  description = "Allow inbound traffic to kong"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = "5432"
    to_port         = "5432"
    protocol        = "TCP"
    security_groups = ["${aws_security_group.kong_instances.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "tf_kong_postgres_sg"
  }
}

resource "aws_db_instance" "kong_db" {
  identifier_prefix      = "tf-kong-db-"
  allocated_storage      = 10
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "9.6.6"
  instance_class         = "db.t2.micro"
  name                   = "kong"
  username               = "kong"
  password               = "${var.pg_pass}"
  db_subnet_group_name   = "${aws_db_subnet_group.kong_db_subnet_group.name}"
  vpc_security_group_ids = ["${aws_security_group.kong_sg.id}"]
}

resource "aws_db_subnet_group" "kong_db_subnet_group" {
  name       = "tf-kong-subnet-group"
  subnet_ids = ["${var.private_subnets}"]

  tags {
    Name = "tf-kong-subnet-group"
  }
}
