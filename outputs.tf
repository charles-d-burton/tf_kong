output "security_group" {
  value = "${aws_security_group.kong_instances.id}"
}

output "launch_configuration" {
  value = "${aws_launch_configuration.kong_lc.id}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.kong_asg.id}"
}

output "kong_admin_alb" {
  value = "${aws_alb.kong_internal_alb.dns_name}"
}

/* output "kong_frontend_alb" {
  value = "${aws_alb.kong-alb.dns_name}"
} */

