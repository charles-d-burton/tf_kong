#Policies for log forwarding
data "aws_iam_policy_document" "cloudwatch_lambda_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "logging_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:Describe*",
      "logs:Get*",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:Describe*",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "logs:Get*",
      "logs:Describe*",
      "logs:TestMetricFilter",
      "sns:Get*",
      "sns:List*",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = ["${var.log_forwarding_arn}"]
  }
}

#Create the log stream, all functions will need this
resource "aws_cloudwatch_log_group" "task_log" {
  name              = "${var.log_group_path}/${var.service_name}"
  retention_in_days = "${var.max_log_retention}"

  tags {
    Application = "${var.service_name}"
  }
}

# Add log filters and have it call lambda 
resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_lambda_filter" {
  count           = "${var.enable_log_forwarding ? 1 : 0 }"
  name            = "ecs-filter-${var.service_name}"
  log_group_name  = "${var.log_group_path}/${var.service_name}"
  filter_pattern  = "${var.filter_pattern}"
  destination_arn = "${var.log_forwarding_arn}"
  depends_on      = ["aws_lambda_permission.allow_cloudwatch"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "null" {}

resource "random_pet" "name" {}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count          = "${var.enable_log_forwarding ? 1 : 0 }"
  statement_id   = "${random_pet.name.id}"
  action         = "lambda:InvokeFunction"
  function_name  = "${var.log_forwarding_name}"
  principal      = "logs.${var.region}.amazonaws.com"
  source_account = "${data.aws_caller_identity.current.account_id}"

  # source_arn     = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:ECS-${var.service_name}:*"
  source_arn = "${aws_cloudwatch_log_group.task_log.arn}"
}

resource "aws_iam_role" "iam_for_logging" {
  count              = "${var.enable_log_forwarding ? 1 : 0 }"
  name               = "logging_${var.service_name}"
  assume_role_policy = "${data.aws_iam_policy_document.cloudwatch_lambda_assume_role.json}"
}

resource "aws_iam_policy" "logging_policy" {
  count       = "${var.enable_log_forwarding ? 1 : 0 }"
  name        = "logging_policy_${var.service_name}"
  path        = "/logs/"
  description = "Policy to access cloudwatch logs for lambda forwarding"
  policy      = "${data.aws_iam_policy_document.logging_policy.json}"
}

resource "aws_iam_policy_attachment" "logging_attach" {
  count      = "${var.enable_log_forwarding  ? 1 : 0 }"
  name       = "logging-attachment-${var.service_name}"
  policy_arn = "${aws_iam_policy.logging_policy.arn}"
  roles      = ["${aws_iam_role.iam_for_logging.name}"]
}
