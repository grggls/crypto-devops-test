# role.tf - a collection of AWS IAM resources as a module
# This module takes no parameters. Further improvements might involve making 
# the 'prod-ci' string a variable that can be changed.
# This module has no tests or output; it has been linted, formatted, and planned

# get the local/calling AWS account ID
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# create a role that can be assumed by anyone in this AWS account
resource "aws_iam_role" "prod_ci_role" {
  name                 = "prod_ci_role"
  max_session_duration = 43200 # 12 hours
  assume_role_policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Terraform = "true"
  }
}

# create a policy with no permissions in it
resource "aws_iam_policy" "prod_ci_policy" {
  name        = "prod_ci_policy"
  path        = "/"
  description = "prod ci policy denying all permisions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "*",
        ]
        Effect   = "Deny"
        Resource = "*"
      },
    ]
  })
}

# attach the no-permissions policy document to the role
resource "aws_iam_role_policy_attachment" "prod_ci_policy_attachment" {
  role       = aws_iam_role.prod_ci_role.name
  policy_arn = aws_iam_policy.prod_ci_policy.arn
}

# create a group
resource "aws_iam_group" "prod_ci_group" {
  name = "prod_ci_group"
}

# the Challenge asks for "A group with the above policy attached"
# assuming this references the permissionless policy, not the assume_role policy
# the assume_role policy refers to any user/group in this account, by design
resource "aws_iam_group_policy" "prod_ci_group_policy" {
  name  = "prod_ci_group_policy"
  group = aws_iam_group.prod_ci_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = aws_iam_policy.prod_ci_policy.policy
}

# create a user
resource "aws_iam_user" "prod_ci_user" {
  name = "prod_ci_user"
  tags = {
    Terraform = "true"
  }
}

# add the user to the group
resource "aws_iam_user_group_membership" "prod_ci_user_group_membership" {
  user = aws_iam_user.prod_ci_user.name

  groups = [
    aws_iam_group.prod_ci_group.name,
  ]
}
