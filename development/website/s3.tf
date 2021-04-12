 resource "null_resource" "ansible-execution" {
   provisioner "local-exec" {
     command = "aws s3 ls"
   }
 }