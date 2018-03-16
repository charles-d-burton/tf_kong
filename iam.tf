data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kong_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

#Policies for lambda invocation

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "kong_cloudwatch_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_role" "kong" {
  name               = "${var.tag_name}-role-${var.region}"
  assume_role_policy = "${data.aws_iam_policy_document.kong_role.json}"
}

/* resource "aws_iam_policy_attachment" "kong" {
  name       = "kong-${var.tag_name}-attachment"
  policy_arn = "${aws_iam_policy.kong.arn}"
  role       = "${aws_iam_role.kong.name}"
} */

resource "aws_iam_policy" "kong_lambda_exection_policy" {
  name        = "kong-${var.tag_name}-lambda"
  description = "Allow kong to execute lambda functions"
  policy      = "${data.aws_iam_policy_document.lambda_policy.json}"
}

resource "aws_iam_policy_attachment" "kong_lambda" {
  name       = "kong-${var.tag_name}-lambda-attach"
  policy_arn = "${aws_iam_policy.kong_lambda_exection_policy.arn}"
  roles      = ["${aws_iam_role.kong.name}"]
}

resource "aws_iam_policy" "kong_cloudwatch_policy" {
  name        = "kong-${var.tag_name}-cwl-attach"
  description = "Allow kong to write to cloudwatch"
  policy      = "${data.aws_iam_policy_document.kong_cloudwatch_policy.json}"
}

resource "aws_iam_policy_attachment" "kong_cloudwatch_attach" {
  name       = "kong-${var.tag_name}-cwl"
  policy_arn = "${aws_iam_policy.kong_cloudwatch_policy.arn}"
  roles      = ["${aws_iam_role.kong.name}"]
}

resource "aws_iam_instance_profile" "kong_instance_profile" {
  name = "${var.tag_name}-instance-profile-${var.region}"
  role = "${aws_iam_role.kong.name}"
}

/* resource "aws_iam_user" "kong" {
  name = "kong"
  path = "/system/"
}

resource "aws_iam_access_key" "kong" {
  user = "${aws_iam_user.kong.name}"
}

resource "aws_iam_user_policy" "kong_user" {
  name   = "kong_user"
  user   = "${aws_iam_user.kong.name}"
  policy = "${data.aws_iam_policy_document.lambda_policy.json}"
} */

