
provider "aws" {
  region     = "ap-southeast-2"
}


# Create a study IAM group
resource "aws_iam_group" "study" {
  name = "study"
  path = "/groups/"
}

# Create a study user
resource "aws_iam_user" "study" {
  name = "study"
  path = "/users/"

  tags = {
    category = "big_three"
  }
}

# Add the user to the group
resource "aws_iam_group_membership" "study" {
  name = "study_group_membership"

  users = [
    aws_iam_user.study.name
  ]

  group = aws_iam_group.study.name
}

