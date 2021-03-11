## User website ##
resource "aws_iam_user" "website" {
  name = "website-terraform"
  path = "/"
}

