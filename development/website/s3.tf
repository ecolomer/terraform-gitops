#tfsec:ignore:AWS002 tfsec:ignore:AWS017 tfsec:ignore:AWS077
# resource "aws_s3_bucket" "ec-test" {
#   bucket = "ec-test.aba.land"
#   policy = data.aws_iam_policy_document.access_policy.json
#
#   tags = {
#     Name = "ec-test-2.aba.land"
#   }
#
#   cors_rule {
#     allowed_headers = ["Authorization", "Content-Length"]
#     allowed_methods = ["GET"]
#     allowed_origins = ["*"]
#     max_age_seconds = 3000
#   }
# }
#
# resource "aws_s3_bucket_public_access_block" "ec-test" {
#   bucket = aws_s3_bucket.ec-test.id
#
#   block_public_acls   = true
#   block_public_policy = true
#   ignore_public_acls = true
#   restrict_public_buckets = true
# }
#
# data "aws_iam_policy_document" "access_policy" {
#   statement {
#     actions   = ["s3:GetObject"]
#     resources = ["arn:aws:s3:::ec-test.aba.land/*"]
#
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#   }
# }
