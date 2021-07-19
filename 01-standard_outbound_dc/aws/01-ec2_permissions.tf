
resource "aws_iam_policy" "ec2_admin" {
  name        = "EC2_Admin"
  path        = "/policies/"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:Describe*"
        ],
        "Resource": [
          "*",
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:Create*",
          "ec2:Delete*",
          "ec2:Attach*",
          "ec2:Detach*",
          "ec2:Associate*"
        ]
        "Resource": "*",
        "Condition": {
          "StringEquals": {"ec2:ResourceTag/environment": "study"}
        }
      },
      {
        "Effect": "Allow",
        "Action": [
            "ec2:Create*",
        ],
        "Resource": "*",
        "Condition": {
          "StringEquals": { 
            "aws:RequestTag/environment": "study"
          }
        }
      },
      { 
        "Effect": "Allow",
        "Action": [
          "ec2:ReplaceRouteTableAssociation"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "ec2_admin" {
  group      = aws_iam_group.study.name
  policy_arn = aws_iam_policy.ec2_admin.arn
}


