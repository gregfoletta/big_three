provider "aws" {
  region     = "ap-southeast-2"
}

resource "aws_iam_group" "study" {
  name = "study"
  path = "/groups/"
}

resource "aws_iam_user" "study" {
  name = "study"
  path = "/users/"

  tags = {
    category = "big_three"
  }
}

resource "aws_iam_access_key" "study" {
  user = aws_iam_user.study.name
}

resource "aws_iam_group_membership" "study" {
  name = "study_group_membership"

  users = [
    aws_iam_user.study.name
  ]

  group = aws_iam_group.study.name
}

resource "aws_iam_policy" "ec2_admin" {
  name        = "EC2_Admin"
  path        = "/policies/"

  policy = jsonencode(
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
          }
        ]
    }
  )
}

resource "aws_iam_group_policy_attachment" "ec2_admin" {
  group      = aws_iam_group.study.name
  policy_arn = aws_iam_policy.ec2_admin.arn
}


