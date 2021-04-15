resource "aws_s3_bucket" "ec-bucket" {
    bucket = "ec-bucket"

    tags {
      Name = "EC Bucket"
    }
}