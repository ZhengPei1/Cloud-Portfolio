# Set up S3 bucket for static website hosting
resource "aws_s3_bucket" "s3_web_bucket" {
  bucket = var.S3_BUCKET_NAME
}

locals {
  content_dir = "../webpage"
  files_to_upload = fileset(local.content_dir, "**") 
}

resource "aws_s3_object" "content" {
  for_each = local.files_to_upload

  bucket = aws_s3_bucket.s3_web_bucket.id 
  key    = each.value
  source = "${local.content_dir}/${each.value}"

  # for content change detection
  etag = filemd5("${local.content_dir}/${each.value}")

  content_type = lookup(
    {
      "html" = "text/html"
      "css"  = "text/css"
      "js"   = "application/javascript"
    },
   
    lower(split(".", each.value)[length(split(".", each.value)) - 1]),
    "application/octet-stream" # Default if extension is unknown
  )
}

resource "aws_s3_bucket_public_access_block" "s3_web_bucket" {
  bucket = aws_s3_bucket.s3_web_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "s3_web_bucket" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.s3_web_bucket.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_web_bucket" {
  bucket = aws_s3_bucket.s3_web_bucket.bucket
  policy = data.aws_iam_policy_document.s3_web_bucket.json
}
