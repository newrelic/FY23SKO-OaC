# Enable cloud integrations to monitor the AWS environment through Terraform with New Relic

The New Relic Cloud integrations are a great way for you to get some great insights into their AWS environment, and link that data to APM, Browser, or even Infrastructure data. The only downside is that it's quite a hassle to set it all up, especially if you have to setup multiple New Relic and/or AWS accounts. Luckily the Observability as Code team has recently released the final bits to make this entire configuration fully automated.

During this part of the workshop we will go through each step on how to set up the Cloud integrations end to end. Now because this requires pretty extensive permissions on the AWS side we will only review the code and not execute it. If you have your own AWS account nothing is stopping you from trying it out. This will be a great example of tying two Terraform providers together to create an end to end automated solution.

## What do we need to set up?

When we look at the [Set up the Amazon CloudWatch Metric Streams integration](https://docs.newrelic.com/docs/infrastructure/amazon-integrations/connect/aws-metric-stream-setup) documentation you will notice we need to set up a couple of things.

1) Set up right permissions
2) Set up New Relic to accept the metric stream
3) Create a Kinesis Data Firehose Delivery Stream
4) Create the Cloudwatch metric stream.

In general this doesn't seem too complicated, but setting this all up manually will probably take you 30 minutes or more, if you don't make any mistakes. So let's take a look at how we can automate this with Terraform.

## 1) Set up right permissions

The first thing we need is to give New Relic access to certain AWS API's. The reason we do this is to enrich CloudWatch metrics with additional service metadata and custom tags. And there's still certain services that are not supported through Metric stream and still rely on API calls.

Setting up a role in AWS is a multi part process. First we need create a [`aws_iam_policy_document`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) linked to a [`aws_iam_role`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) linking the New Relic AWS account to your own AWS account. This will allow New Relic to access the AWS API in your name.

```
data "aws_iam_policy_document" "newrelic_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [754728514883]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.NEW_RELIC_ACCOUNT_ID]
    }
  }
}

resource "aws_iam_role" "newrelic_aws_role" {
  name               = "NewRelicInfrastructure-Integrations"
  description        = "New Relic Cloud integration role"
  assume_role_policy = data.aws_iam_policy_document.newrelic_assume_policy.json
}
```

The code above does not give New Relic full access to your AWS account, in this case New Relic can't do anything. This means the next step is that we need to define exactly which API endpoints New Relic is allowed to access. The configurion below creates a custom [`aws_iam_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) and links it to the `iam_role` through a [`aws_iam_role_policy_attachment`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment).

```
resource "aws_iam_policy" "newrelic_aws_permissions" {
  name        = "NewRelicCloudStreamReadPermissions"
  description = ""
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "budgets:ViewBudget",
        "cloudtrail:LookupEvents",
        "config:BatchGetResourceConfig",
        "config:ListDiscoveredResources",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeVpcs",
        "ec2:DescribeNatGateways",
        "ec2:DescribeVpcEndpoints",
        "ec2:DescribeSubnets",
        "ec2:DescribeNetworkAcls",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcPeeringConnections",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeVpnConnections",
        "health:DescribeAffectedEntities",
        "health:DescribeEventDetails",
        "health:DescribeEvents",
        "tag:GetResources",
        "xray:BatchGet*",
        "xray:Get*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "newrelic_aws_policy_attach" {
  role       = aws_iam_role.newrelic_aws_role.name
  policy_arn = aws_iam_policy.newrelic_aws_permissions.arn
}
```

The permissions above will retrieve all the data New Relic can gather from your AWS account. If you have any concerns about a specific permissions it's ok to remove them, keeping in mind that this could mean you see less data in New Relic. Set

The examples above contain some great examples on how you can link multiple resources within Terraform. For example the `aws_iam_role_policy_attachment` resource links to `aws_iam_role` and `aws_iam_policy` resource. A great feature of Terraform is that the code does not have to be in order, but that Terraform will keep into account the dependencies or links between resources, and execute them in the right order. In the case the link is not explicit, or you're not referencing other resources but do want them to be executed in order you can use [`depends_on`](https://www.terraform.io/language/meta-arguments/depends_on).

## Set up New Relic to accept the metric stream

We've not set up all the required permissions and can move on to linking New Relic to your AWS account. For this we will use the new [`newrelic_cloud_aws_link_account`](https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/resources/cloud_aws_link_account) resource in the New Relic Terraform provider.

```
resource "newrelic_cloud_aws_link_account" "newrelic_cloud_integration" {
  arn = aws_iam_role.newrelic_aws_role.arn
  metric_collection_mode = "PUSH"
  name = "production"
  depends_on = [aws_iam_role_policy_attachment.newrelic_aws_policy_attach]
}
```

Here we can find a great example of `depends_on`. As you can see we are not directly or indirectly refering the `aws_iam_role_policy_attachment` resource, but it is critical to the succesfull operation of `newrelic_cloud_aws_link_account`. By setting `depends_on` we make sure `aws_iam_role_policy_attachment` finishes before `newrelic_cloud_aws_link_account` is executed. We are using the `metric_collection_mode` `PUSH` mode here, as AWS is pushing the metrics towards New Relic. The `PULL` approach will be available in the future to pull metrics from AWS.

One part that is missing here, and will be released in the near future is the set up of additional integrations. AWS Metric streams don't yet support every metric available, so some integrations will still use the `PULL` approach. For more information [check out the New Relic docs](https://docs.newrelic.com/docs/infrastructure/amazon-integrations/connect/aws-metric-stream#integrations-not-replaced-streams).

## Create a Kinesis Data Firehose Delivery Stream

We now have the right permissions set, and New Relic is ready to receive metrics from AWS. The next step is to set up a Kenesis Data Firehost Deliver stream. You're probably wondering how this fits into the system, so there's a small diagram below that hopefully clarify to create the picture.

```
AWS Cloudwatch data -> AWS Cloudwatch Metric Stream -> Kenesis Firehose -> New Relic Endpoint -> New Relic Database
```

As you can see the data takes quite a trip, but because everything is event based the metric stream is actually faster than the polling method that's still available with New Relic today. When new AWS Cloudwatch data is added it is pushed through automatically towards New Relic, so it only takes a couple of seconds to show up in New Relic. For the polling method ('PULL') it can take up to 15 minutes before New Relic fetches the data after it's available in Cloudwatch.

To create a Kenesis Firehose we'll again have to create a couple of permissions, an S3 bucket (as a backup data store), the firehose itself, and the New Relic endpoint where the firehose will send the data. Let's start at the end, and work our way backwards. This seems like a strange way to look at it, but it happens a lot when building Terraform resources. You'll understand when we work our way through it.

What we want to do is to set up a firehose that sends data to New Relic.

```
resource "aws_kinesis_firehose_delivery_stream" "newrelic_firehost_stream" {
  name        = "newrelic_firehost_stream"
  destination = "http_endpoint"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_newrelic_role.arn
    bucket_arn         = aws_s3_bucket.newrelic_aws_bucket.arn
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }

  http_endpoint_configuration {
    url                = "https://aws-api.newrelic.com/cloudwatch-metrics/v1" # US
    # url                = "https://aws-api.eu01.nr-data.net/cloudwatch-metrics/v1" # EU
    name               = "New Relic"
    access_key         = newrelic_api_access_key.newrelic_aws_access_key.key
    buffering_size     = 1
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose_newrelic_role.arn
    s3_backup_mode     = "FailedDataOnly"

    request_configuration {
      content_encoding = "GZIP"
    }
  }
}
```

As you see we create a `aws_kinesis_firehose_delivery_stream` configured to send data to New Relic. If you would run this it won't work. First of all, we're missing permissions (`aws_iam_role`), a `newrelic_api_access_key`, and an `aws_s3_bucket`. Also we haven't configured Cloudwatch to send data to the `aws_kinesis_firehose_delivery_stream` through `aws_cloudwatch_metric_stream`, so even if this code would work, we're not going to receive data.

Before we give you all the answers I want to challenge you to create all the missing pieces using Terraform. Use the [AWS Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) documentation in combination with the [New Relic docs on Metric stream](https://docs.newrelic.com/docs/infrastructure/amazon-integrations/connect/aws-metric-stream-setup/) to complete the code. Don't worry if you get stuck, especially around the permissions as this is a complicated setup to complete.

## Finish up

I hope you've taken the time to do this by yourself, as it's always the best way to learn. If you got stuck anywhere, no worries with the steps below we are going to finish our AWS Cloudwatch Metrics stream.

Looking at the code for `aws_kinesis_firehose_delivery_stream`, we need to create the following things:

1) S3 bucket, and IAM role so that `aws_kinesis_firehose_delivery_stream` can access the bucket
2) Retrieve a New Relic license key to use for the endpoint, and the right permissions for the stream
3) Set up Cloudwatch to stream metrics to our `aws_kinesis_firehose_delivery_stream` again with the right permissions

Let's get into it. If you got stuck on a specific part, try not to peak at the others.

### S3 bucket

Creating an S3 bucket is easy to do in Terraform, you only need the `aws_s3_bucket` and `aws_s3_bucket_acl` resource. They will take care of the required configuration, and will make sure `aws_kinesis_firehose_delivery_stream` is able to access the bucket.

```
resource "aws_s3_bucket" "newrelic_aws_bucket" {
  bucket = "newrelic-aws-bucket"
}

resource "aws_s3_bucket_acl" "newrelic_aws_bucket_acl" {
  bucket = aws_s3_bucket.newrelic_aws_bucket.id
  acl    = "private"
}
```

### New Relic license key

The New Relic Terraform provider has a great resource to retrieve any kind of API key through Terraform. This is a great way to automate other kind of deployments, without having to manually share credentials. In this step we also create the right permissions for the firehost to push metrics to New Relic.

```
resource "newrelic_api_access_key" "newrelic_aws_access_key" {
  account_id  = var.NEW_RELIC_ACCOUNT_ID
  key_type    = "INGEST"
  ingest_type = "LICENSE"
  name        = "Ingest License key"
  notes       = "AWS Cloud Integrations Firehost Key"
}

resource "aws_iam_role" "firehose_newrelic_role" {
  name = "firehose_newrelic_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
```

### Cloudwatch metric stream

The last piece of the puzzle is sending the Cloudwatch metrics through pipeline. In this case we create an `aws_iam_role` for Cloudwatch to send data to firehose, and for the firehose to allow data from Cloudwatch. As a last step we configure the `aws_cloudwatch_metric_stream` to start sending metrics.

```
resource "aws_iam_role" "metric_stream_to_firehose" {
  name = "metric_stream_to_firehose_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "streams.metrics.cloudwatch.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "metric_stream_to_firehose" {
  name = "default"
  role = aws_iam_role.metric_stream_to_firehose.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "firehose:PutRecord",
                "firehose:PutRecordBatch"
            ],
            "Resource": "${aws_kinesis_firehose_delivery_stream.newrelic_firehost_stream.arn}"
        }
    ]
}
EOF
}

resource "aws_cloudwatch_metric_stream" "newrelic_metric_stream" {
  name          = "newrelic-metric-stream"
  role_arn      = aws_iam_role.metric_stream_to_firehose.arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.newrelic_firehost_stream.arn
  output_format = "opentelemetry0.7"
}
```

## That's it

You can now proceed to [Part 5 - New Relic CLI](./Part_5-Bonus_round_CLI.md)

## Full example

We've added a complete example of the code above, including the extra integrations on the Terraform documentation: https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/guides/cloud_integrations_guide
