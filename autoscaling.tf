resource "aws_autoscaling_group" "kong_asg" {
  name                 = "${var.tag_name}-asg"
  launch_configuration = "${aws_launch_configuration.kong_lc.name}"
  max_size             = "${var.max_cluster_size}"
  min_size             = "${var.min_cluseter_size}"
  desired_capacity     = "${var.min_cluster_size}"
  force_delete         = true
  vpc_zone_identifier  = ["${var.alb_subnets_private}"]
  target_group_arns    = ["${aws_alb_target_group.tf_alb_http.arn}", "${aws_alb_target_group.tf_alb_admin.arn}", "${aws_alb_target_group.tf_alb_internal.arn}"]

  tag {
    key                 = "Name"
    value               = "${var.tag_name}-${count.index}"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "KongRole"
    value               = "Server"
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_policy" "kong_scale_up" {
  name                   = "kong-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.kong_asg.name}"
}

resource "aws_autoscaling_policy" "kong_scale_down" {
  name                   = "kong-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.kong_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "kong-cpu-high"
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
  alarm_name          = "kong-cpu-low"
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
  alarm_name          = "kong-network-high"
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
  alarm_name          = "kong-network-low"
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
