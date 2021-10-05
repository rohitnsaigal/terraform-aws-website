# Providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = "us-east-1"
}

/* S3 bucket creation */

resource "aws_s3_bucket" "site" {
  bucket        = var.site_domain
  acl           = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

/* Grant public permission to S3 bucket  */
resource "aws_s3_bucket_policy" "public_read" {
  bucket = var.site_domain
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowReadFromAll"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*",
        ]
      },
    ]
  })
}

/*Cloudfront distribution to serve website over HTTPS*/

resource "aws_cloudfront_distribution" "site" {
  http_version = "http2"

  origin {
    domain_name = aws_s3_bucket.site.website_endpoint
    origin_id   = "origin-${var.site_domain}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }


  }

  enabled             = true
  default_root_object = "index.html"

  aliases = concat([var.site_domain, "www.${var.site_domain}"])

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    target_origin_id = "origin-${var.site_domain}"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only"
  }
}


# DNS validation to create a hosted zone
resource "aws_acm_certificate" "cert" {
  domain_name               = var.site_domain
  subject_alternative_names = ["www.${var.site_domain}"]
  validation_method         = "DNS"
}

# THE FOLLOWING IS ONLY NEEDED IF CREAING A NEW HOSTED ZONE
# data "aws_route53_zone" "zone" {
#   name = "${var.route53_domain}"
#   private_zone=false
# }


resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# route 53 redirect record 
resource "aws_route53_record" "www" {
  zone_id = var.route53_zone_id
  name    = var.site_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# route 53 redirect record for www. prefix endpoint version of website
resource "aws_route53_record" "redirect-wwww" {
  zone_id = var.route53_zone_id
  name    = "www.${var.site_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
} 