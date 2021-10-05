output "s3_hosted_zone_id" {
  value = aws_s3_bucket.site.hosted_zone_id
}

output "s3_bucket" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.site.*.domain_name
}

output "cloudfront_hosted_zone" {
  value = aws_cloudfront_distribution.site.*.hosted_zone_id
}
