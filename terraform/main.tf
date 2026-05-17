# ─── S3 Bucket ────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "website" {
  # S3 names must be lowercase; appending account ID ensures global uniqueness.
  bucket = "devops-hosting-956651462310"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ─── S3 Logs Bucket ───────────────────────────────────────────────────────────

resource "aws_s3_bucket" "logs" {
  bucket = "devops-hosting-logs-956651462310"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 server access logging requires BucketOwnerPreferred so that AWS can
# deliver log objects owned by the bucket owner, not the logging service.
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_logging" "website" {
  bucket        = aws_s3_bucket.website.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# Allow public policies while still blocking public ACLs
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true   # block ACL-based public grants
  block_public_policy     = false  # allow the bucket policy below to grant public read
  ignore_public_acls      = true
  restrict_public_buckets = false  # allow public access via bucket policy
}

# Static website hosting — CloudFront default root handles index.html,
# but this is required per project spec.
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Bucket policy:
#   1. Allow s3:GetObject to everyone (public read)
#   2. Allow all read actions (s3:Get* / s3:List*) to the SmartSimar IAM user
#   3. CloudFront OAC GetObject (signed requests from CloudFront)
#   4. Explicit Deny of all non-read actions to every principal EXCEPT SmartSimar
#      — SmartSimar is excluded so Terraform can still manage the bucket.
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
      {
        Sid    = "AllowSmartSimarReadActions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::956651462310:user/SmartSimar"
        }
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Sid    = "AllowCloudFrontOACGetObject"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      },
      {
        # Deny every non-read action to all principals except SmartSimar.
        # SmartSimar is excluded so Terraform retains full management rights.
        Sid       = "DenyNonReadActionsForOthers"
        Effect    = "Deny"
        Principal = "*"
        NotAction = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
        Condition = {
          StringNotEquals = {
            "aws:PrincipalArn" = "arn:aws:iam::956651462310:user/SmartSimar"
          }
        }
      }
    ]
  })
}

# ─── CloudFront Origin Access Control ─────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ─── CloudFront Distribution ───────────────────────────────────────────────────

locals {
  s3_origin_id = "S3-devops-hosting"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  comment             = "${var.project_name} static site distribution"

  # REST API endpoint (regional domain) + OAC for signed requests
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # AWS managed CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    compress        = true
  }

  # Return index.html for 404s (handles direct URL access)
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
