
# Here we configure Terraform to use the New Relic and AWS provider.
# We've already configured the right configuration for this workshop, so no changes are needed.
# When working with customers you can find the instructions for this on the Terraform registry:
# New Relic: https://registry.terraform.io/providers/newrelic/newrelic/latest/docs/guides/provider_configuration
# AWS: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

terraform {
    # We can define which is the minimum version of Terraform to have installed locally
    required_version = "~> 1.1"
    required_providers {
        # Here we define which version of the New Relic provider we want to use
        # This allows customers to fix to a certain version of the provider
        # giving them more control when to upgrade as some versions might contain
        # breaking changes. In general the Observability as code team tries to
        # avoid this, but it does happen. Advise your customers always to use
        # the latest version
        newrelic = {
            source  = "newrelic/newrelic"
            version = "~> 2.40.0"
        }

        # We now do the same for AWS
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.5"
        }
    }
}


# After we've downloaded the latest version of the New Relic provider, we need to
# configure it with the right API keys. Although we have the option to do it here
# directly that's considered a bad practice. Because Terraform files are usually
# added to a source control system like Git, it could mean that credentials become
# exposed to anyone that has access to that system. So we just say that we want to
# use New Relic and AWS.
provider "newrelic" { }
provider "aws" {
    region = var.AWS_REGION
}

# Go back to the `Part_1-Setting_up_Terraform.md` readme
# once you think you're done with this file and learn how to set up your
# authentication credentials
