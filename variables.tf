#EC2 variables
variable "ami" {
  description = "AWS AMI Id, if you change, make sure it is compatible with instance type, not all AMIs allow all instance types "

  default = {
    us-west-1      = "ami-02eada62"
    us-west-2      = "ami-e689729e"
    us-east-1      = "ami-8c1be5f6"
    us-east-2      = "ami-c5062ba0"
    sa-east-1      = "ami-f1344b9d"
    eu-west-1      = "ami-acd005d5"
    eu-west-2      = "ami-1a7f6d7e"
    eu-central-1   = "ami-c7ee5ca8"
    ca-central-1   = "ami-fd55ec99"
    ap-southeast-1 = "ami-0797ea64"
    ap-southeast-2 = "ami-8536d6e7"
    ap-south-1     = "ami-4fc58420"
    ap-northeast-1 = "ami-2a69be4c"
    ap-northeast-2 = "ami-9bec36f5"
  }
}

variable "key_name" {
  description = "The SSH key to use"
}

variable "region" {
  description = "The region of AWS, for AMI lookups."
}

variable "instance_type" {
  description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
  default     = "t2.micro"
}

variable "tag_name" {
  default = "tf-kong"
}

#Networking
variable "vpc_id" {
  description = "VPC to place the cluster in"
}

variable "private_subnets" {
  description = "List of subnets to launch instances into"
  type        = "list"
}

variable "public_subnets" {
  description = "List of public subnet to place instances"
  type        = "list"
}

variable "private_alb_arn" {
  description = "The ALB to serve the admin interface"
}

variable "private_alb_sg" {
  description = "The security group of the private ALB"
}

variable "public_alb_arn" {
  description = "The ALB that is exposed to the internet"
}

variable "public_alb_sg" {
  description = "The security group of the public ALB"
}

/* variable "zone_id_internal" {
  description = "The Route53 zone to place the dns entry in"
} */

variable "ssl_certificate_id" {}

#variable "cloudfront_cert" {}

variable "pg_pass" {}

variable "notification_arn" {
  description = "SNS topic to send autoscaling alerts to"
}

#Cluster variables to set the minimum and maximum cluster size
variable "min_cluster_size" {
  description = "The number of servers to launch."
  default     = 2
}

variable "max_cluster_size" {
  description = "The maximum number of nodes"
  default     = 5
}
