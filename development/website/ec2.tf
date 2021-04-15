## Instance website ##
resource "aws_instance" "ec-website" {
  ami           = "ami-0ff8a91507f77f867"
  instance_type = "t1.2xlarge" # invalid type!
  iam_instance_profile = "invalid-profile"
}