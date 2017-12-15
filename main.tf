#Security group for the instances themselves
resource "aws_security_group" "kong_instances" {
  name        = "${var.tag_name}-sg"
  description = "Kong internal traffic and maintenance."
  vpc_id      = "${var.vpc_id}"

  // These are for internal traffic
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = ["${var.private_alb_sg}", "${var.public_alb_sg}"]
  }

  ingress {
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = ["${var.private_alb_sg}", "${var.public_alb_sg}"]
  }

  // These are for maintenance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // This is for outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Load the launch config with the templated userdata to start kong
resource "aws_launch_configuration" "kong_lc" {
  name_prefix     = "${var.tag_name}-"
  image_id        = "${lookup(var.ami, var.region)}"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.kong_instances.id}"]
  user_data       = "${data.template_file.kong_config.rendered}"
  key_name        = "${var.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "external_allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${var.public_alb_sg}"
}

/* resource "aws_security_group_rule" "external_allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${var.public_alb_sg}"
} */

resource "aws_security_group_rule" "internal_allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${var.private_alb_sg}"
}

/* resource "aws_security_group_rule" "internal_allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "${var.private_alb_sg}"
} */

resource "aws_security_group_rule" "internal_allow_admin" {
  type              = "ingress"
  from_port         = 8001
  to_port           = 8001
  protocol          = "tcp"
  cidr_blocks       = ["${data.aws_vpc.selected_vpc.cidr_block}"]
  security_group_id = "${var.private_alb_sg}"
}

resource "aws_security_group_rule" "internal_allow_admin_secure" {
  type              = "ingress"
  from_port         = 8002
  to_port           = 8002
  protocol          = "tcp"
  cidr_blocks       = ["${data.aws_vpc.selected_vpc.cidr_block}"]
  security_group_id = "${var.private_alb_sg}"
}

#Setup target groups
resource "aws_alb_target_group" "external_http_target_group" {
  name        = "${var.tag_name}-alb-tcp"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  health_check {
    path    = "/status"
    port    = 8001
    matcher = 200
  }
}

resource "aws_alb_target_group" "internal_admin_target_group" {
  name     = "${var.tag_name}-alb-admin"
  port     = 8001
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"

  /* health_check {
    path    = "/status"
    port    = 8001
    matcher = 200
  } */
}

resource "aws_alb_target_group" "internal_http_target_group" {
  name     = "${var.tag_name}-alb-internal"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    path    = "/status"
    port    = 8001
    matcher = 200
  }
}

resource "aws_alb_listener" "front_end_https" {
  load_balancer_arn = "${var.public_alb_arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.ssl_certificate_id}"

  default_action {
    target_group_arn = "${aws_alb_target_group.external_http_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "front_end_http" {
  load_balancer_arn = "${var.public_alb_arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.external_http_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "front_end_http_internal" {
  load_balancer_arn = "${var.private_alb_arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.internal_http_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "front_end_https_admin" {
  load_balancer_arn = "${var.private_alb_arn}"
  port              = "8001"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.ssl_certificate_id}"

  default_action {
    target_group_arn = "${aws_alb_target_group.internal_admin_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "front_end_http_admin" {
  load_balancer_arn = "${var.private_alb_arn}"
  port              = "8002"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.internal_admin_target_group.arn}"
    type             = "forward"
  }
}

/* resource "aws_route53_record" "internal_alb_record" {
  zone_id = "${var.zone_id_internal}"
  name    = "api.${var.region}.${var.env}.gaia.aws"
  type    = "A"

  alias {
    name                   = "${aws_alb.kong-internal-alb.dns_name}"
    zone_id                = "${aws_alb.kong-internal-alb.zone_id}"
    evaluate_target_health = true
  }
} */


/* resource "aws_cloudfront_distribution" "api_gateway_distribution" {
  origin {
    domain_name = "${var.domain_name}"
    origin_id   = "kong-${var.env}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Cloudfront in front of Kong"

  #Uncomment to enable logging
  logging_config {
    include_cookies = false
    bucket          = "mylogs.s3.amazonaws.com"
    prefix          = "myprefix"
  }

  #aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "kong-${var.env}"
    compress         = true

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward           = "whitelist"
        whitelisted_names = ["auth"]
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  price_class = "PriceClass_200"
  restrictions {
    geo_restriction {
      restriction_type = "none"

      //locations        = ["US", "CA", "GB", "DE"]
    }
  }
  tags {
    Environment = "${var.env}"
  }
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = "${var.cloudfront_cert}"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1"
  }
} */

