locals {
  bucket_names = {
    artifacts = "wimiline-deploy-${data.aws_caller_identity.current.account_id}-${random_id.suffix.hex}"
    backup    = "wimiline-backup-${data.aws_caller_identity.current.account_id}-${random_id.suffix.hex}"
    audit     = "wimiline-audit-${data.aws_caller_identity.current.account_id}-${random_id.suffix.hex}"
  }
}
resource "terraform_data" "bucket" {
  for_each = local.bucket_names
  input    = { name = each.value }
  provisioner "local-exec" {
    command = "python bucket_lifecycle.py ensure ${self.input.name}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "python bucket_lifecycle.py destroy ${self.input.name}"
  }
}
