variable "site_domain" {
  type        = string
  description = "The domain of your website domain"
}

# variable "route53_domain"{
#     type = string
#     description = "The domain of your website; This is necessary if you dont already have a hosted zone for your domain"
# }

variable "route53_zone_id" {
  type        = string
  description = "zone id for the hosted zone you would like to host your website on"
  default     = ""
}