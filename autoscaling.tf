resource "aws_autoscaling_group" "kong_asg" {
  name                 = "${var.service_name}-asg"
  launch_configuration = "${aws_launch_configuration.kong_lc.name}"
  max_size             = "${var.max_cluster_size}"
  min_size             = "${var.min_cluster_size}"
  desired_capacity     = "${var.min_cluster_size}"
  force_delete         = true
  vpc_zone_identifier  = ["${var.private_subnets}"]
  target_group_arns    = ["${aws_alb_target_group.external_http_target_group.arn}", "${aws_alb_target_group.internal_admin_target_group.arn}", "${aws_alb_target_group.internal_http_target_group.arn}"]

  tag {
    key                 = "Name"
    value               = "${var.service_name}-${count.index}"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "KongRole"
    value               = "Server"
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_policy" "kong_scale_up" {
  name                   = "${var.service_name}-kong-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.kong_asg.name}"
}

resource "aws_autoscaling_policy" "kong_scale_down" {
  name                   = "${var.service_name}-kong-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.kong_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.service_name}-kong-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu for high utilization on agent hosts"

  alarm_actions = [
    "${aws_autoscaling_policy.kong_scale_up.arn}",
  ]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.kong_asg.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.service_name}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors ec2 cpu for low utilization on agent hosts"

  alarm_actions = [
    "${aws_autoscaling_policy.kong_scale_down.arn}",
  ]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.kong_asg.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "network_high" {
  alarm_name          = "${var.service_name}-network-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "15000000000"                                                          # 15 Gigabit
  alarm_description   = "This metric monitors ec2 network for high utilization on agent hosts"

  alarm_actions = [
    "${aws_autoscaling_policy.kong_scale_up.arn}",
  ]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.kong_asg.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "network_low" {
  alarm_name          = "${var.service_name}-kong-network-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "15000000000"                                                         # 15 Gigabit
  alarm_description   = "This metric monitors ec2 network for low utilization on agent hosts"

  alarm_actions = [
    "${aws_autoscaling_policy.kong_scale_down.arn}",
  ]

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.kong_asg.name}"
  }
}
