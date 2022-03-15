
# Check if we can get access to our New Relic account
variable "NEW_RELIC_CHECK_ACCOUNT_ID" {}
data "newrelic_account" "data_check_newrelic" {
  scope = "global"
  account_id = var.NEW_RELIC_CHECK_ACCOUNT_ID
}

# Check if we have access to our AWS account
variable "AWS_REGION" {
  type    = string
  default = "us-east-1"
}

variable "AWS_AVAILABILITY_ZONE" {
  type    = string
  default = "us-east-1a"
}

data "aws_ec2_instance_type" "data_check_aws" {
  instance_type = "t2.micro"
}

