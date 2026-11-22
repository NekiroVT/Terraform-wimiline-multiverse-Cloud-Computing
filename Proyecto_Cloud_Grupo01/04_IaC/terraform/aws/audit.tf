resource "aws_s3_bucket_public_access_block" "audit" {
  bucket                  = terraform_data.bucket["audit"].output.name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid = "AWSCloudTrailAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${terraform_data.bucket["audit"].output.name}"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:us-east-1:${data.aws_caller_identity.current.account_id}:trail/wimiline-auditoria"]
    }
  }
  statement {
    sid = "AWSCloudTrailWrite"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${"arn:aws:s3:::${terraform_data.bucket["audit"].output.name}"}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:us-east-1:${data.aws_caller_identity.current.account_id}:trail/wimiline-auditoria"]
    }
  }
}
resource "aws_s3_bucket_policy" "audit" {
  bucket = terraform_data.bucket["audit"].output.name
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}
resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  bucket = terraform_data.bucket["audit"].output.name
  rule {
    id     = "retention-90-days"
    status = "Enabled"
    filter {}
    expiration { days = 90 }
  }
}
resource "aws_cloudtrail" "main" {
  name                       = "wimiline-auditoria"
  s3_bucket_name             = terraform_data.bucket["audit"].output.name
  is_multi_region_trail      = false
  enable_log_file_validation = true
  depends_on                 = [aws_s3_bucket_policy.audit]
}
