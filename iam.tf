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

resource "aws_iam_role" "kong" {
  name               = "${var.tagName}-role-${var.region}"
  assume_role_policy = "${data.aws_iam_policy_document.kong_role.json}"
}

resource "aws_iam_policy_attachment" "kong" {
  name       = "kong-${var.tagName}-attachment"
  policy_arn = "${aws_iam_policy.kong.arn}"
  role       = "${aws_iam_role.kong.name}"
}

resource "aws_iam_instance_profile" "kong-instance-profile" {
  name  = "kong-${var.tagName}-instance-profile-${var.region}"
  roles = ["${aws_iam_role.kong.name}"]
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

resource "aws_iam_user" "kong" {
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
}
