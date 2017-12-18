variable "ubuntu_ami_name" {
  type = "string"
  description = "The name of the ubuntu ami to pull from"
  default = "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"
}

variable "amazon_ami_name" {
  type = "string"
  description = "The name of the Amazon Linux ami to pull from"
  default = "amzn-ami-hvm-*-x86_64-gp2"
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
