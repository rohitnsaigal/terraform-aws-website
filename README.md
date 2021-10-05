This module is intended to help you establish all the insfrastructure needed in order to host a website on AWS. 

This module will:
    - create an S3 bucket and give that bucket read permissions 
    - create a cloudfront distribution to serve the s3 bucket over https 
    - create a certificate for your website and a validation record for that certificate
    - create Route53 records so that the provided website points to the cloudfront distribution 

This module assumes you registered your domain through AWS and therefore already have a hosted zone created for that domain. If you do not have a domain yet, [register one through AWS](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html)

How to use this module
```terraform

module "my_new_website" {
    source="gitlab.com"
    site_domain="mywebsitename.myregistereddomain"
    route53_zone_id="route53zoneidforyourdomain"
}

output "s3_bucket_for_my_new_website"{
    value=module.my_new_website.s3_bucket
}
    

```

Once the infrastructure has been established, then you simply need to upload your website contents to the s3 bucket.

Until you upload an index.html document, if you visit your newly created website you will get a 404