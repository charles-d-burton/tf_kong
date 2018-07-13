# Terraform to Create Kong API Gateway

## Usage
```hcl
module "kong_gateway" {
  source              = "git@github.com:charles-d-burton/tf_kong?ref=v1.1.0"
  key_name            = "<ssh-key>"
  service_name        = "<unique versioned name>"
  region              = "${var.region}"
  vpc_id              = "${data.terraform_remote_state.vpc.vpc_id}"
  private_subnets     = "${data.terraform_remote_state.vpc.private_subnets}"
  public_subnets      = "${data.terraform_remote_state.vpc.public_subnets}"
  private_alb_arn     = "${data.terraform_remote_state.alb.internal_alb_arn}"
  private_alb_sg      = "${data.terraform_remote_state.alb.internal_security_group_id}"
  public_alb_arn      = "${data.terraform_remote_state.alb.external_alb_arn}"
  public_alb_sg       = "${data.terraform_remote_state.alb.external_security_group_id}"
  ssl_certificate_id  = "${var.ssl_certificate_id}"
  pg_pass             = "${data.aws_ssm_parameter.postgres.value}"
  notification_arn    = ["${data.terraform_remote_state.sns_alerting.arn}"]
  instance_type       = "${var.instance_type}"
  admin_inbound_cidr  = ["${var.admin_inbound_cidr}"]
  log_forwarding_arn  = "${data.terraform_remote_state.log_forwarding.arn}"
  log_forwarding_name = "${data.terraform_remote_state.log_forwarding.name}"
}
```
```bash
$terraform apply
```

## Details

### Cluster
This will create a Kong cluster configured to run on an Amazon Linux AMI.  The default scaling parameters are as few as 2 nodes and as many as 5 nodes.  When the apply is finished you will have a Kong cluster with the admin port set to 8002 exposed on the internal load balancer.  Any parameters inside the launch configuration block and be non-destructively configured.  Simply change the associated variable and apply.  Once it completes manually reboot a single node at a time to make the change take effect.  This allows for zero downtime deploys.

### Autoscaling
The cluster is configured to scale on CPU utilization.

### Logging
The `kong_setup.sh` contains installs the awslogging agent.  The terraform sets up and configures logging to go to cloudwatch by default.  Additionally if file logging is configured via the Kong plugin you can send your `error`, `access`, and `request` logs to `/home/ec2-user/kong/logs` and have them appear in cloudwatch.
