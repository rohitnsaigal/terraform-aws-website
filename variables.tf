provider "aws" {
  region = var.aws_region
}

variable "site_domain" {
  type        = string
  description = "The domain of your website domain"
}

variable "route53_domain"{
    type = string
    description = "The domain of your website; This is necessary if you dont already have a hosted zone for your domain"
    default = null
}

variable "route53_zone_id" {
  type        = string
  description = "zone id for the hosted zone you would like to host your website on"
  default     = ""
}

variable "aws_region" {
    type = string
    description = "region you want your resources to reside"
    default = "us-west-2"
}