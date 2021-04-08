## User website ##
resource "aws_iam_user" "ec-website" {
  name = "ec-website"
  path = "/"
}

